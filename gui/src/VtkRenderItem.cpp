#include "VtkRenderItem.h"

#include <vtkPointPicker.h>
#include <vtkCommand.h>
#include <vtkCallbackCommand.h>
#include <vtkRendererCollection.h>
#include <vtkRenderWindowInteractor.h>
#include <vtkRenderWindow.h>

static double framePerSecond;

void fpsCallback(vtkObject* obj, unsigned long event, void* clientData, void*) {
    vtkRenderer* renderer = static_cast<vtkRenderer*>(obj);
    auto item = static_cast<VTKRenderItem*>(clientData);

    double timeInSeconds = renderer->GetLastRenderTimeInSeconds();
    framePerSecond = 1.0 / timeInSeconds;

    emit item->fpsChanged();
}

double VTKRenderItem::fps() {
    return framePerSecond;
}

VTKRenderItem::VTKRenderItem() {
    vtkNew<vtkCallbackCommand> command;
    command->SetCallback(fpsCallback);
    command->SetClientData(this);
    this->renderer()->AddObserver(vtkCommand::EndEvent, command);
}

void VTKRenderItem::sync() {
    for (;;) {
        std::function<void()> command;
        {
            std::lock_guard<std::mutex> lock(commandMutex_);
            if (commandQueue_.empty()) break;
            command = std::move(commandQueue_.front());
            commandQueue_.pop();
        }
        command();
    }

    QQuickVTKRenderItem::sync();
}
