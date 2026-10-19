#include "intersectionLineNode.h"

#include <pcl/common/io.h>
#include <pcl/segmentation/sac_segmentation.h>
#include <Eigen/Core>

using namespace pcl;

bool calcLine(const ModelCoefficientsPtr &first, const ModelCoefficientsPtr &second,
              const ModelCoefficientsPtr &line) {
    if (!first || !second || first->values.size() < 4 || second->values.size() < 4)
        return false;
    const Eigen::Vector3f n1(first->values[0], first->values[1], first->values[2]);
    const Eigen::Vector3f n2(second->values[0], second->values[1], second->values[2]);
    const Eigen::Vector3f direction = n1.cross(n2);
    const float squaredNorm = direction.squaredNorm();
    if (squaredNorm < 1e-12f) return false;
    const Eigen::Vector3f origin =
        (second->values[3] * n1 - first->values[3] * n2).cross(direction) /
        squaredNorm;
    const Eigen::Vector3f unitDirection = direction.normalized();
    line->values = {origin.x(), origin.y(), origin.z(),
                    unitDirection.x(), unitDirection.y(), unitDirection.z()};
    return true;
}
QQmlComponent*  IntersectionLineNode::delegate(QQmlEngine& engine) noexcept
{
    static std::unique_ptr<QQmlComponent> delegate;
    if ( !delegate )
        delegate = std::make_unique<QQmlComponent>(&engine, "qrc:/ui/nodes/IntersectionLineNode.qml");
    return delegate.get();
}

IntersectionLineNode::~IntersectionLineNode() {
    if(workThread_.joinable()) {
        workThread_.join();
    }
}

void IntersectionLineNode::inNodeOutputChanged()
{
    FlowNode::inNodeOutputChanged();

    const auto inputs = inputOutputs();
    startWorker(workThread_, [this, inputs]{
        std::vector<PointIndicesPtr> pointIndices;
        std::vector<ModelCoefficientsPtr> modelCoefficients;
        for (const auto &input : inputs) {
            auto inOutput = input.value<PointCloud<PointXYZRGB>::Ptr>();
            if (inOutput && !inOutput->empty()) {
                SACSegmentation<PointXYZRGB> segmentTool;
                segmentTool.setOptimizeCoefficients(true);
                segmentTool.setModelType(SACMODEL_PLANE);
                segmentTool.setMethodType(SAC_RANSAC);
                segmentTool.setDistanceThreshold(FLT_MAX);
                segmentTool.setInputCloud(inOutput);

                PointIndicesPtr indices(new PointIndices);
                ModelCoefficientsPtr coefficients(new ModelCoefficients);
                segmentTool.segment(*indices, *coefficients);
                pointIndices.emplace_back(indices);
                if (coefficients->values.size() >= 4)
                    modelCoefficients.emplace_back(coefficients);
            }
            else {
                qInfo() << "[Intersection Line Node]: cloud is empty!";
            }
        }
        
        if(modelCoefficients.size() == 2) {
            ModelCoefficientsPtr lines(new ModelCoefficients);
            if (calcLine(modelCoefficients[0], modelCoefficients[1], lines))
                setOutput(QVariant::fromValue(lines));

            qInfo() << "[Intersection Line Node]: Completed!";
        }
    });
}
