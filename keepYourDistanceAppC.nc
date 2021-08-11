/**
 *  @author Federico Di Cesare	10529764
 *  @author Luca Giacometti		10524482
 */

#include "keepYourDistance.h"

configuration keepYourDistanceAppC {}

implementation {


/****** COMPONENTS *****/
  components MainC, keepYourDistanceC as App;
  
  components new AMSenderC(AM_KEEPYOURDISTANCE_MSG);
  components new AMReceiverC(AM_KEEPYOURDISTANCE_MSG);
  components ActiveMessageC;
  
  //components new TimerMilliC() as receiver_t;
  components new TimerMilliC() as sender_t;
  
/****** INTERFACES *****/
  //Boot interface
  App.Boot -> MainC.Boot;

  /****** Wire the other interfaces down here *****/
  
  //Send and Receive interfaces
  App.AMSend -> AMSenderC;
  App.Receive -> AMReceiverC;
  
  //Radio Control
  App.SplitControl -> ActiveMessageC;
  
  //Interfaces to access package fields
  App.Packet -> AMSenderC;
  App.PAck -> AMSenderC;
  
  //Timer interface
  //App.ReceiverTimer -> receiver_t;
  App.SenderTimer -> sender_t;

}

