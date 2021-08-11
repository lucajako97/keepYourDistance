/**
 *  @author Federico Di Cesare	10529764
 *  @author Luca Giacometti		10524482
 */

configuration keepYourDistanceAppC {}

implementation {
  components MainC, keepYourDistanceC as App, LedsC;
  components new AMSenderC(AM_KEEPYOURDISTANCE_MSG);
  components new AMReceiverC(AM_KEEPYOURDISTANCE_MSG);
  components new TimerMilliC();
  components ActiveMessageC;
  components PrintfC;
  components SerialStartC;
  
  App.Boot -> MainC.Boot;
  
  App.Receive -> AMReceiverC;
  App.AMSend -> AMSenderC;
  App.AMControl -> ActiveMessageC;
  App.MilliTimer -> TimerMilliC;
  App.Leds -> LedsC;
  App.Packet -> AMSenderC;
}

