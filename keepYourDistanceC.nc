/**
 *  @author Federico Di Cesare	10529764
 *  @author Luca Giacometti		10524482
 */
#include "Timer.h"
#include "keepYourDistance.h"
#include "printf.h"

module keepYourDistanceC @safe() {
  uses {
    interface Leds;
    interface Boot;
    interface Receive;
    interface AMSend;
    interface Timer<TMilli> as MilliTimer;
    interface SplitControl as AMControl;
    interface Packet;
  }
}
implementation {

  message_t packet;

  bool locked;

  uint16_t last_id = -1;
  uint16_t counter = 0;
  
  event void Boot.booted() {
    call AMControl.start();
  }

  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
      call MilliTimer.startPeriodic(500);

    }
    else {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) {
    // do nothing
  }
  
  event void MilliTimer.fired() {
    
    dbg("KeepYourDistance", "KeepYourDistance: timer fired, counter is %hu.\n", counter);
    
    if (locked) {
      return;
    }
    else {
      keepyourdistance_msg_t* rcm = 
              (keepyourdistance_msg_t*)call Packet.getPayload(&packet, sizeof(keepyourdistance_msg_t));
              
      if (rcm == NULL) {
      return;
      }

      rcm->id = TOS_NODE_ID;
      
      if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(keepyourdistance_msg_t)) == SUCCESS) {
      dbg("KeepYourDistance", "KeepYourDistance: packet sent.\n", counter); 
      locked = TRUE;
      }
    }
  }

  event message_t* Receive.receive(message_t* bufPtr, 
           void* payload, uint8_t len) {
    dbg("KeepYourDistance", "Received packet of length %hhu.\n", len);
    
    if (len != sizeof(keepyourdistance_msg_t)) {return bufPtr;}
    else {
      keepyourdistance_msg_t* rcm = (keepyourdistance_msg_t*)payload;
      
      if (last_id == rcm->id){
        counter++;
      }
      else{
        last_id = rcm->id;
        counter = 1;
      }

      printfflush();
      printf(">> I am %u, I received from %u, counter is %u <<\n", TOS_NODE_ID, rcm->id, counter);
      printfflush();
    }

    if (counter == 10){
      printfflush();
      printf(">> Too close to: %u <<\n", last_id);
      printfflush();
      counter = 0;
    }
      
      return bufPtr;
  }


  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    if (&packet == bufPtr) {
      locked = FALSE;
    }
  }

}