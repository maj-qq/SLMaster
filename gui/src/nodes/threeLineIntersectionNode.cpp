#include "threeLineIntersectionNode.h"

#include <Eigen/Eigen>
#include <pcl/ModelCoefficients.h>

#include <vtkPoints.h>
#include <vtkPolyDataMapper.h>
#include <vtkActor.h>
#include <vtkPolyLine.h>
#include <vtkLineSource.h>
#include <vtkProperty.h>

using namespace pcl;
using namespace Eigen;

bool calcLineIntersectionPoint(const ModelCoefficientsPtr &lineA,
                               const ModelCoefficientsPtr &lineB,
                               Vector3f &crossPoint) {
    if (!lineA || !lineB || lineA->values.size() < 6 || lineB->values.size() < 6)
        return false;
    const Vector3f p(lineA->values[0], lineA->values[1], lineA->values[2]);
    const Vector3f q(lineB->values[0], lineB->values[1], lineB->values[2]);
    const Vector3f u(lineA->values[3], lineA->values[4], lineA->values[5]);
    const Vector3f v(lineB->values[3], lineB->values[4], lineB->values[5]);
    const float a = u.dot(u), b = u.dot(v), c = v.dot(v);
    const float denominator = a * c - b * b;
    if (std::abs(denominator) < 1e-12f) return false;
    const Vector3f w = p - q;
    const float t = (b * v.dot(w) - c * u.dot(w)) / denominator;
    const float s = (a * v.dot(w) - b * u.dot(w)) / denominator;
    crossPoint = (p + t * u + q + s * v) * 0.5f;
    return crossPoint.allFinite();
}

QQmlComponent* ThreeLineIntersectionLineNode::delegate(QQmlEngine& engine) noexcept
{
    static std::unique_ptr<QQmlComponent> delegate;
    if ( !delegate )
        delegate = std::make_unique<QQmlComponent>(&engine, "qrc:/ui/nodes/ThreeLineIntersectionNode.qml");
    return delegate.get();
}

ThreeLineIntersectionLineNode::~ThreeLineIntersectionLineNode() {
    if(workThread_.joinable()) {
        workThread_.join();
    }
}

void ThreeLineIntersectionLineNode::inNodeOutputChanged()
{
    FlowNode::inNodeOutputChanged();

    const auto inputs = inputOutputs();
    const double length = length_, width = width_, height = height_;
    startWorker(workThread_, [this, inputs, length, width, height]{
        std::vector<ModelCoefficientsPtr> lines;
        for (const auto &input : inputs) {
            auto inOutput = input.value<ModelCoefficientsPtr>();
            if (inOutput && inOutput->values.size() >= 6) {
                lines.emplace_back(inOutput);
            }
            else {
                qInfo() << "[Three Line Intersection Node]: cloud is empty!";
            }
        }
        
        if(lines.size() == 3) {
            Vector3f crossPoint;
            if (!calcLineIntersectionPoint(lines[0], lines[1], crossPoint)) return;
            Eigen::Vector3f direcLength, direcWidth, direcHeight;
            direcLength << lines[0]->values[3], lines[0]->values[4], lines[0]->values[5];
            direcWidth << lines[1]->values[3], lines[1]->values[4], lines[1]->values[5];
            direcHeight << lines[2]->values[3], lines[2]->values[4], lines[2]->values[5];
            Eigen::Vector3f posLengthEnd = crossPoint + length * direcLength;
            Eigen::Vector3f posWidthEnd = crossPoint + width * direcWidth;
            Eigen::Vector3f posHeightEnd = crossPoint + height * direcHeight;
        
            vtkNew<vtkPoints> points;
            points->InsertNextPoint(crossPoint(0), crossPoint(1), crossPoint(2));
            points->InsertNextPoint(posLengthEnd(0), posLengthEnd(1), posLengthEnd(2));
            points->InsertNextPoint(crossPoint(0), crossPoint(1), crossPoint(2));
            points->InsertNextPoint(posWidthEnd(0), posWidthEnd(1), posWidthEnd(2));
            points->InsertNextPoint(crossPoint(0), crossPoint(1), crossPoint(2));
            points->InsertNextPoint(posHeightEnd(0), posHeightEnd(1), posHeightEnd(2));
        
            vtkNew<vtkPolyLine> line;
            line->GetPointIds()->SetNumberOfIds(6);
            line->GetPointIds()->SetId(0, 0);
            line->GetPointIds()->SetId(1, 1);
            line->GetPointIds()->SetId(2, 2);
            line->GetPointIds()->SetId(3, 3);
            line->GetPointIds()->SetId(4, 4);
            line->GetPointIds()->SetId(5, 5);
        
            vtkNew<vtkCellArray> linesCellArray;
            linesCellArray->InsertNextCell(line);

            vtkNew<vtkPolyData> polyData;
            polyData->SetPoints(points);
            polyData->SetLines(linesCellArray);
        
            vtkNew<vtkPolyDataMapper> polyDataMapper;
            polyDataMapper->SetInputData(polyData);
        
            auto lineActor = vtkSmartPointer<vtkActor>::New();
            lineActor->SetMapper(polyDataMapper);
            lineActor->GetProperty()->SetColor(0, 1, 0);
            lineActor->GetProperty()->SetLineWidth(2);

            setOutput(QVariant::fromValue(lineActor));

            qInfo() << "[Three Line Intersection Node]: Completed!";
        }
    });
}
