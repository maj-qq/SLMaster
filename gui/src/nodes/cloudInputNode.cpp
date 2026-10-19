#include "cloudInputNode.h"

#include "CameraEngine.h"

#include "pcl/io/ply_io.h"
#include <QUrl>

using namespace pcl;
using namespace pcl::io;

CloudInputNode::CloudInputNode() : FlowNode{FlowNode::Type::CloudInput}, mode_(CloudInputMode::FromCamera), filePath_("") {
    setOutput(QVariant::fromValue(pcl::PointCloud<pcl::PointXYZRGB>::Ptr(new pcl::PointCloud<pcl::PointXYZRGB>)));
    connect(this, &CloudInputNode::filePathChanged, this, &CloudInputNode::readPlyFile);
}

CloudInputNode::~CloudInputNode() {
    if(workThread_.joinable()) {
        workThread_.join();
    }
}

QQmlComponent*  CloudInputNode::delegate(QQmlEngine& engine) noexcept
{
    static std::unique_ptr<QQmlComponent> delegate;
    if ( !delegate )
        delegate = std::make_unique<QQmlComponent>(&engine, "qrc:/ui/nodes/CloudInputNode.qml");
    return delegate.get();
}

bool CloudInputNode::readPlyFile(QString path) {
    startWorker(workThread_, [this, path]{
        if(path != "") {
            PointCloud<PointXYZRGB>::Ptr cloudPtr(new PointCloud<PointXYZRGB>);
            if(0 == loadPLYFile(path.toLocal8Bit().toStdString(), *cloudPtr)) {
                setOutput(QVariant::fromValue(cloudPtr));
            }
        }

        qInfo() << "[Cloud Input Node]: Completed!";
    });

    return true;
}

void CloudInputNode::setMode(const CloudInputMode mode) {
    mode_ = mode;

    emit modeChanged(mode);
}

void CloudInputNode::setFilePath(const QString& filePath) {
    if(mode_ == CloudInputMode::FromFile) {
        const QUrl url(filePath);
        filePath_ = url.isLocalFile() ? url.toLocalFile() : filePath;
        emit filePathChanged(filePath_);
    }
}

void CloudInputNode::updateSource() {
    if(mode_ == CloudInputMode::FromCamera) {
        auto frame = CameraEngine::instance()->getCurFrame();
        if (frame.pointCloud_ && !frame.pointCloud_->empty())
            setOutput(QVariant::fromValue(frame.pointCloud_));
    }
    else {
        //点云源文件无需更新，仅通过手动选择文件夹更新,因此直接发射信号
        outputChanged();
    }
}
