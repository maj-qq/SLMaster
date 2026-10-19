#include "passThroughFilterNode.h"

#include <pcl/filters/passthrough.h>

using namespace pcl;

QQmlComponent*  PassThroughFilterNode::delegate(QQmlEngine& engine) noexcept
{
    static std::unique_ptr<QQmlComponent>   delegate;
    if ( !delegate )
        delegate = std::make_unique<QQmlComponent>(&engine, "qrc:/ui/nodes/PassThroughFilterNode.qml");
    return delegate.get();
}

PassThroughFilterNode::~PassThroughFilterNode() {
    if(workThread_.joinable()) {
        workThread_.join();
    }
}

void PassThroughFilterNode::inNodeOutputChanged()
{
    FlowNode::inNodeOutputChanged();

    const auto inputs = inputOutputs();
    const bool filterX = filterX_, filterY = filterY_, filterZ = filterZ_;
    const double minX = minX_, maxX = maxX_, minY = minY_, maxY = maxY_;
    const double minZ = minZ_, maxZ = maxZ_;
    startWorker(workThread_, [this, inputs, filterX, filterY, filterZ,
                              minX, maxX, minY, maxY, minZ, maxZ]{
        PointCloud<PointXYZRGB>::Ptr outPutCloud(new PointCloud<PointXYZRGB>);
        for (const auto &input : inputs) {
            auto inOutput = input.value<PointCloud<PointXYZRGB>::Ptr>();
            if (inOutput && !inOutput->empty()) {
                PassThrough<PointXYZRGB> filter;
                auto current = inOutput;
                const auto apply = [&](const char *field, double min, double max) {
                    PointCloud<PointXYZRGB>::Ptr filtered(new PointCloud<PointXYZRGB>);
                    filter.setInputCloud(current);
                    filter.setFilterFieldName(field);
                    filter.setFilterLimits(min, max);
                    filter.filter(*filtered);
                    current = filtered;
                };
                if (filterX) apply("x", minX, maxX);
                if (filterY) apply("y", minY, maxY);
                if (filterZ) apply("z", minZ, maxZ);
                *outPutCloud += *current;

                qInfo() << "[Pass Through Filter Node]: Completed!";
            }
            else {
                qInfo() << "[Pass Through Filter Node]: cloud is empty!";
            }
        }
        setOutput(QVariant::fromValue(outPutCloud));
    });
}
