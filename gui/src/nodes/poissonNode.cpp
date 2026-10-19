#include "poissonNode.h"

#include <pcl/common/io.h>
#include <pcl/features/normal_3d.h>
#include <pcl/search/kdtree.h>
#include <pcl/surface/poisson.h>

using namespace pcl;
using namespace pcl::search;

QQmlComponent*  PoissonNode::delegate(QQmlEngine& engine) noexcept
{
    static std::unique_ptr<QQmlComponent> delegate;
    if ( !delegate )
        delegate = std::make_unique<QQmlComponent>(&engine, "qrc:/ui/nodes/PoissonNode.qml");
    return delegate.get();
}

PoissonNode::~PoissonNode() {
    if(workThread_.joinable()) {
        workThread_.join();
    }
}

void PoissonNode::inNodeOutputChanged()
{
    FlowNode::inNodeOutputChanged();

    const auto inputs = inputOutputs();
    const int kSearch = static_cast<int>(kSearch_);
    const int degree = static_cast<int>(degree_), depth = static_cast<int>(maxDepth_);
    const int isoDivide = static_cast<int>(isoDivide_);
    const int solverDivide = static_cast<int>(solverDivide_);
    const double samples = minSamplePoints_, scale = scale_;
    const bool confidence = confidence_;
    startWorker(workThread_, [this, inputs, kSearch, degree, depth, isoDivide,
                              solverDivide, samples, scale, confidence]{
        PolygonMesh::Ptr mesh(new PolygonMesh);
        for (const auto &input : inputs) {
            auto inOutput = input.value<PointCloud<PointXYZRGB>::Ptr>();
            if (inOutput && !inOutput->empty()) {
                NormalEstimation<PointXYZRGB, Normal> nes;
                PointCloud<Normal>::Ptr normals(new PointCloud<Normal>);
                pcl::search::KdTree<PointXYZRGB>::Ptr kdTree(new pcl::search::KdTree<PointXYZRGB>);

                nes.setInputCloud(inOutput);
                nes.setSearchMethod(kdTree);
                nes.setKSearch(kSearch);
                nes.compute(*normals);

                PointCloud<PointXYZRGBNormal>::Ptr cloud_with_normals(new PointCloud<PointXYZRGBNormal>);
                concatenateFields(*inOutput, *normals, *cloud_with_normals);

                pcl::search::KdTree<PointXYZRGBNormal>::Ptr kdTree2(new pcl::search::KdTree<PointXYZRGBNormal>);
                kdTree2->setInputCloud(cloud_with_normals);

                Poisson<PointXYZRGBNormal> pn;
                pn.setConfidence(confidence);
                pn.setDegree(degree);
                pn.setDepth(depth);
                pn.setIsoDivide(isoDivide);
                pn.setOutputPolygons(false);
                pn.setSamplesPerNode(samples);
                pn.setScale(scale);
                pn.setSolverDivide(solverDivide);
                pn.setInputCloud(cloud_with_normals);
                pn.setSearchMethod(kdTree2);
                pn.performReconstruction(*mesh);

                qInfo() << "[Poisson Node]: Completed!";
            }
            else {
                qInfo() << "[Poisson Node]: cloud is empty!";
            }
        }

        setOutput(QVariant::fromValue(mesh));
    });
}
