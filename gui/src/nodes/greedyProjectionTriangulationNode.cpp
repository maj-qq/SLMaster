#include "greedyProjectionTriangulationNode.h"

#include <pcl/common/io.h>
#include <pcl/features/normal_3d.h>
#include <pcl/search/kdtree.h>
#include <pcl/surface/gp3.h>

using namespace pcl;
using namespace pcl::search;

QQmlComponent*  GreedyProjectionTriangulationNode::delegate(QQmlEngine& engine) noexcept
{
    static std::unique_ptr<QQmlComponent> delegate;
    if ( !delegate )
        delegate = std::make_unique<QQmlComponent>(&engine, "qrc:/ui/nodes/GreedyProjectionTriangulationNode.qml");
    return delegate.get();
}

GreedyProjectionTriangulationNode::~GreedyProjectionTriangulationNode() {
    if(workThread_.joinable()) {
        workThread_.join();
    }
}

void GreedyProjectionTriangulationNode::inNodeOutputChanged()
{
    FlowNode::inNodeOutputChanged();

    const auto inputs = inputOutputs();
    const int kSearch = static_cast<int>(kSearch_);
    const int maxNeighbors = static_cast<int>(maxNearestNumber_);
    const double radius = searchRadius_, mu = multiplier_;
    const double minAngle = minimumAngle_, maxAngle = maximumAngle_;
    const double maxSurfaceAngle = maximumSurfaceAngle_;
    const bool normalConsistency = normalConsistency_;
    startWorker(workThread_, [this, inputs, kSearch, maxNeighbors, radius, mu,
                              minAngle, maxAngle, maxSurfaceAngle, normalConsistency]{
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

                GreedyProjectionTriangulation<PointXYZRGBNormal> gp;
                gp.setSearchRadius(radius);
                gp.setMu(mu);
                gp.setMaximumNearestNeighbors(maxNeighbors);
                gp.setMaximumSurfaceAngle(maxSurfaceAngle);
                gp.setMaximumAngle(maxAngle / 180 * 3.1415926535);
                gp.setMinimumAngle(minAngle / 180 * 3.1415926535);
                gp.setNormalConsistency(normalConsistency);
                gp.setInputCloud(cloud_with_normals);
                gp.setSearchMethod(kdTree2);
                gp.reconstruct(*mesh);

                qInfo() << "[Greedy Projection Triangulation Node]: Completed!";
            }
            else {
                qInfo() << "[Greedy Projection Triangulation Node]: In node output cloud is empty!";
            }
        }

        setOutput(QVariant::fromValue(mesh));
    });
}
