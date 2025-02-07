import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class BikePowerDerivedFieldsApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
    }

    function onStop(state as Dictionary?) as Void {
    }

    function getInitialView() {
        return [ new BikePowerDerivedFieldsView() ];
    }

}

function getApp() as BikePowerDerivedFieldsApp {
    return Application.getApp() as BikePowerDerivedFieldsApp;
}
