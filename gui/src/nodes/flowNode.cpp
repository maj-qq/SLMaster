#include "flowNode.h"
#include <QMetaObject>
#include <QThread>

QQmlComponent*  FlowNode::delegate(QQmlEngine& engine) noexcept {
    static std::unique_ptr<QQmlComponent>   qan_FlowNode_delegate;
    if ( !qan_FlowNode_delegate )
        qan_FlowNode_delegate = std::make_unique<QQmlComponent>(&engine, "qrc:/ui/nodes/FlowNode.qml");
    return qan_FlowNode_delegate.get();
}

void FlowNode::inNodeOutputChanged(){ }

std::vector<QVariant> FlowNode::inputOutputs() const {
    std::vector<QVariant> outputs;
    for (const auto node : get_in_nodes()) {
        const auto input = qobject_cast<FlowNode *>(node);
        if (input && input->getOutput().isValid())
            outputs.push_back(input->getOutput());
    }
    return outputs;
}

void FlowNode::setOutput(QVariant output) {
    if (QThread::currentThread() != thread()) {
        QMetaObject::invokeMethod(this, [this, output] { setOutput(output); },
                                  Qt::QueuedConnection);
        return;
    }
    _output = output;
    emit outputChanged();
}
