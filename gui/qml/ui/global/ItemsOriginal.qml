pragma Singleton

import QtQuick 2.15
import FluentUI 1.0

FluObject{

    property var navigationView
    function navigate(item) {
        item.count = 0;
        navigationView.push(item.url);
    }

    function rename(item, newName){
        if(newName && newName.trim().length>0){
            item.title = newName;
        }
    }

    FluPaneItem{
        id:item_device
        title: Lang.device
        icon: FluentIcons.Camera
        url: "qrc:/ui/page/Page_Device.qml"
        onTap: navigate(item_device)
    }

    FluPaneItem{
        id:item_calibration
        title: Lang.calibration
        icon: FluentIcons.Ruler
        url: "qrc:/ui/page/Page_Calibration.qml"
        onTap: navigate(item_calibration)
    }

    FluPaneItem{
        id:item_scan_mode
        title: Lang.scan_mode
        icon: FluentIcons.SetTile
        url: "qrc:/ui/page/Page_ScanMode.qml"
        onTap: navigate(item_scan_mode)
    }

    FluPaneItem{
        id:item_scan
        title: Lang.scan
        icon: FluentIcons.Scan
        url: "qrc:/ui/page/Page_Scan.qml"
        onTap: navigate(item_scan)
    }

    FluPaneItem{
        id:item_post_process
        title: Lang.post_process
        icon: FluentIcons.Processing
        url: "qrc:/ui/page/Page_PostProcess.qml"
        onTap: navigate(item_post_process)
    }

    FluPaneItem{
        id:item_postProcessOutput
        title: Lang.post_process_output
        icon: FluentIcons.View
        url: "qrc:/ui/page/Page_PostProcessOutput.qml"
        onTap: navigate(item_postProcessOutput)
    }

    function getRecentlyAddedData(){
        var arr = []
        for(var i=0;i<children.length;i++){
            var item = children[i]
            if(item instanceof FluPaneItem && item.recentlyAdded){
                arr.push(item)
            }
            if(item instanceof FluPaneItemExpander){
                for(var j=0;j<item.children.length;j++){
                    var itemChild = item.children[j]
                    if(itemChild instanceof FluPaneItem && itemChild.recentlyAdded){
                        arr.push(itemChild)
                    }
                }
            }
        }
        arr.sort(function(o1,o2){ return o2.order-o1.order })
        return arr
    }

    function getRecentlyUpdatedData(){
        var arr = []
        var items = navigationView.getItems();
        for(var i=0;i<items.length;i++){
            var item = items[i]
            if(item instanceof FluPaneItem && item.recentlyUpdated){
                arr.push(item)
            }
        }
        return arr
    }

    function getSearchData(){
        if(!navigationView){
            return
        }
        var arr = []
        var items = navigationView.getItems();
        for(var i=0;i<items.length;i++){
            var item = items[i]
            if(item instanceof FluPaneItem){
                if (item.parent instanceof FluPaneItemExpander)
                {
                    arr.push({title:`${item.parent.title} -> ${item.title}`,key:item.key})
                }
                else
                    arr.push({title:item.title,key:item.key})
            }
        }
        return arr
    }

    function startPageByItem(data){
        navigationView.startPageByItem(data)
    }

}
