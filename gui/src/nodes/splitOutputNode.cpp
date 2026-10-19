#include "SplitOutputNode.h"

#include <pcl/point_cloud.h>
#include <pcl/point_types.h>

using namespace pcl;

QQmlComponent *SplitOutputNode::delegate(QQmlEngine &engine) noexcept {
    static std::unique_ptr<QQmlComponent> delegate;
    if (!delegate)
        delegate = std::make_unique<QQmlComponent>(
            &engine, "qrc:/ui/nodes/SplitOutputNode.qml");
    return delegate.get();
}

void SplitOutputNode::inNodeOutputChanged() {
    FlowNode::inNodeOutputChanged();

    if (get_in_nodes().size() == 0) return;
    const auto inNode = get_in_nodes().at(0);
    const auto inFlowNode = qobject_cast<FlowNode*>(inNode);

    if (inFlowNode == nullptr || !inFlowNode->getOutput().isValid())
        return;

    auto inOutput = inFlowNode->getOutput().value<std::vector<PointCloud<PointXYZRGB>::Ptr>>();

    if (portIndex_ < 0 || static_cast<size_t>(portIndex_) >= inOutput.size() ||
        !inOutput[portIndex_]) {
        qInfo() << "[Split Output Node]: In node output cloud is empty!";
    }
    else {
        setOutput(QVariant::fromValue(inOutput[portIndex_]));
    }

    qInfo() << "[Split Output Node]: Completed!";
}
