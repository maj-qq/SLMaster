#include "statisticalOutlierRemovalNode.h"

#include <pcl/filters/statistical_outlier_removal.h>

using namespace pcl;

QQmlComponent*  StatisticalOutlierRemovalNode::delegate(QQmlEngine& engine) noexcept
{
    static std::unique_ptr<QQmlComponent>   delegate;
    if ( !delegate )
        delegate = std::make_unique<QQmlComponent>(&engine, "qrc:/ui/nodes/StatisticalOutlierRemovalNode.qml");
    return delegate.get();
}

StatisticalOutlierRemovalNode::~StatisticalOutlierRemovalNode() {
    if(workThread_.joinable()) {
        workThread_.join();
    }
}

void StatisticalOutlierRemovalNode::inNodeOutputChanged()
{
    FlowNode::inNodeOutputChanged();

    const auto inputs = inputOutputs();
    const int k = static_cast<int>(k_);
    const double threshold = stdThreshold_;
    startWorker(workThread_, [this, inputs, k, threshold]{
        PointCloud<PointXYZRGB>::Ptr outPutCloud(new PointCloud<PointXYZRGB>);
        for (const auto &input : inputs) {
            auto inOutput = input.value<PointCloud<PointXYZRGB>::Ptr>();
            if (inOutput && !inOutput->empty()) {
                StatisticalOutlierRemoval<PointXYZRGB> filter;
                filter.setMeanK(k);
                filter.setStddevMulThresh(threshold);
                filter.setInputCloud(inOutput);
                filter.filter(*outPutCloud);

                qInfo() << "[Statistical Outlier Removal Node]: Completed!";
            }
            else {
                qInfo() << "[Statistical Outlier Removal Node]: cloud is empty!";
            }
        }
        setOutput(QVariant::fromValue(outPutCloud));
    });
}
