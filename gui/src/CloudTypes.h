#pragma once

#include <QMetaType>
#include <pcl/ModelCoefficients.h>
#include <pcl/PolygonMesh.h>
#include <pcl/point_cloud.h>
#include <pcl/point_types.h>
#include <vtkActor.h>
#include <vtkSmartPointer.h>

Q_DECLARE_METATYPE(pcl::PointCloud<pcl::PointXYZRGB>::Ptr)
Q_DECLARE_METATYPE(pcl::PolygonMesh::Ptr)
Q_DECLARE_METATYPE(pcl::ModelCoefficients::Ptr)
Q_DECLARE_METATYPE(vtkSmartPointer<vtkActor>)
