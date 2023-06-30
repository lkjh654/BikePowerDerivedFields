import Toybox.Activity;
import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;
import Toybox.FitContributor;
import Toybox.System;

const SPEED_RECORD_ID = 0;
const DISTANCE_RECORD_ID = 1;
const TOTAL_DISTANCE_SESSION_ID = 2;

const DISTANCE_NATIVE_NUM_RECORD_MESG = 5;
const SPEED_NATIVE_NUM_RECORD_MESG = 6;

const TOTAL_DISTANCE_NATIVE_NUM_SESSION_MESG = 9;

const DISTANCE_UNITS = "m";
const SPEED_UNITS = "m/s";

class BikePowerDerivedFieldsView extends WatchUi.SimpleDataField {

    private var Cd = 0.63; // drag coefficient
    private var A = 0.509; // Frontal area A(m2)
    private var Rho = 1.22601; // Air density Rho (kg/m3)
    private var a = 0.5 * Cd * A * Rho;

    private var Vhw = 0.0; // Speed of headwind [m/s]
    private var b = Vhw * Cd * A * Rho;

    private var W = 80.0; // Total weight W (kg)
    private var G = 0.0; // Percent grade of hill G (negative for downhill) (%)
    private var Crr = 0.005; // Coefficient of rolling resistance Crr
    private var c = (9.8067 * W * (Math.sin(Math.atan(G/100.0)) + Crr * Math.cos(Math.atan(G/100.0)))) + (0.5 * Cd * A * Rho * Vhw * Vhw);

    private var Lossdt = 2.0; // Drivetrain loss Lossdt (%)

    private var distance = 0.0;
    private var timerRunning = false;
    private var lastSpeed = 0.0;
    private var lastUpdateMs = null;

    private var speedField;
    private var distanceField;
    private var totalDistanceField;

    // Set the label of the data field here.
    function initialize() {
        SimpleDataField.initialize();
        label = "Dst | Spd";
        distanceField = createField("distance", DISTANCE_RECORD_ID, FitContributor.DATA_TYPE_UINT32, { :nativeNum=>DISTANCE_NATIVE_NUM_RECORD_MESG, :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>DISTANCE_UNITS });
        totalDistanceField = createField("total_distance", TOTAL_DISTANCE_SESSION_ID, FitContributor.DATA_TYPE_UINT32, { :nativeNum=>TOTAL_DISTANCE_NATIVE_NUM_SESSION_MESG, :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>DISTANCE_UNITS });
        speedField = createField("speed", SPEED_RECORD_ID, FitContributor.DATA_TYPE_UINT16, { :nativeNum=>SPEED_NATIVE_NUM_RECORD_MESG, :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>SPEED_UNITS });
    }

    // The given info object contains all the current workout
    // information. Calculate a value and return it in this method.
    // Note that compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().
    function compute(info as Activity.Info) as Numeric or Duration or String or Null {
        var formattedSpeed = "-";

        if (info has :currentPower && timerRunning) {
            if (info.currentPower != null) {
                var currentSpeed = computeVelocity(info.currentPower.toFloat());
                var currentTime = System.getTimer();
                if (lastUpdateMs != null) {
                    var timeDeltaInSeconds = (currentTime - lastUpdateMs) / 1000.0;
                    var averageSpeed = (lastSpeed + currentSpeed) / 2.0;
                    var distanceDelta = averageSpeed * timeDeltaInSeconds;
                    distance = distance + distanceDelta;

                    speedField.setData(currentSpeed.toNumber());

                    formattedSpeed = convertMpsToKmph(currentSpeed).format("%.2f");

                    lastUpdateMs = currentTime;
                    lastSpeed = currentSpeed;
                }
            }
        }

        distanceField.setData(distance.toNumber());
        totalDistanceField.setData(distance.toNumber());

        var formattedDistance = convertMtoKm(distance).format("%.2f");

        return formattedDistance + " | " + formattedSpeed; 
    }

    // based on https://www.gribble.org/cycling/power_v_speed.html
    // result in m/s
    private function computeVelocity(power as Float) as Float {
        var d = -(1.0 - Lossdt/100.0) * power;

        var Q = (3.0 * a * c - b * b) / (9.0 * a * a);
        var R = (9.0 * a * b * c - 27.0 * a * a * d - 2.0 * b * b * b) / (54.0 * a * a * a);
        var S = cubeRoot(R + Math.sqrt(Q * Q * Q + R * R));
        var T = cubeRoot(R - Math.sqrt(Q * Q * Q + R * R));

        var Vgs = S + T - (b / (3.0 * a));

        return Vgs;
    }

    private function convertMtoKm(m as Float) as Float {
        return m / 1000.0;
    }

    private function convertMpsToKmph(mps as Float) as Float {
        return mps * 3.6;
    }

    private function cubeRoot(value as Float) as Float{
        if(value < 0) {
            return -Math.pow(-value, 1.0/3.0);
        }
        return Math.pow(value, 1.0/3.0);
    }

    function onTimerPause() {
    	stopTimer();
    }
    
    function onTimerResume() {
    	startTimer();
    }
    
    function onTimerStart() {
    	startTimer();
    }
    
    function onTimerStop() {
    	stopTimer();
    }

    private function startTimer() {
        timerRunning = true;
        lastUpdateMs = System.getTimer();
        lastSpeed = 0.0;
    }

    private function stopTimer() {
        timerRunning = false;
        lastUpdateMs = null;
    }
}
