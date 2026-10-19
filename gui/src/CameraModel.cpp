#include "cameraModel.h"
#include <QCollator>
#include <QDir>
#include <QFileInfo>

CameraModel::CameraModel(QObject *parent) : QAbstractListModel(parent) {
  roleNames_.insert(FileName, "FileName");
}

CameraModel::~CameraModel() {}

int CameraModel::rowCount(const QModelIndex &parent) const {
  Q_UNUSED(parent);
  return imgs_.count();
}

QVariant CameraModel::data(const QModelIndex &index, int role) const {
  if (!index.isValid()) return QVariant();

  switch (role) {
    case FileName: {
      return imgs_.value(index.row());
    }
    default:
      break;
  }

  return QVariant();
}

void CameraModel::emplace_back(const QString &imgInfo) {
  beginResetModel();

  imgs_.push_back(imgInfo);

  endResetModel();
}

int CameraModel::erase(const QString &imgInfo) {
  const int index = imgs_.indexOf(imgInfo);
  if (index < 0) return -1;
  beginResetModel();
  imgs_.removeAt(index);
  endResetModel();
  return index;
}

void CameraModel::erase(int locIndex) {
  if (locIndex < 0 || locIndex >= imgs_.size()) return;
  beginResetModel();
  imgs_.removeAt(locIndex);
  endResetModel();
}

void CameraModel::recurseImg(const QString &folderUrl) {
  beginResetModel();
  imgs_.clear();
  const QUrl url(folderUrl);
  curFolderPath_ = url.isLocalFile() ? url.toLocalFile() : folderUrl;
  QDir dir(curFolderPath_);
  const auto files = dir.entryInfoList({"*.bmp", "*.png", "*.jpg", "*.jpeg"},
                                       QDir::Files | QDir::Readable, QDir::NoSort);
  for (const auto &file : files) imgs_.append(file.fileName());
  QCollator collator;
  collator.setNumericMode(true);
  std::sort(imgs_.begin(), imgs_.end(),
            [&collator](const QString &a, const QString &b) {
              return collator.compare(a, b) < 0;
            });
  endResetModel();

  emit updateImgs();
}

QHash<int, QByteArray> CameraModel::roleNames() const { return roleNames_; }
