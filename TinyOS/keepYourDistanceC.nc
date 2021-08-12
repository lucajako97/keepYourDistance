/**
 *  @author Federico Di Cesare	10529764
 *  @author Luca Giacometti		10524482
 */
#include "Timer.h"
#include "keepYourDistance.h"
#include "printf.h"

#define MAX_MOTES 10

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

  uint8_t last_counter[MAX_MOTES];
  uint8_t start_counter[MAX_MOTES];

  uint8_t internal_counter = 0;
  
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
      rcm->seq_n = internal_counter;

      internal_counter++;
      
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

      uint8_t id = rcm->id -1;

      /**printf("[%u] Received from >%u< with counter %u\n", TOS_NODE_ID, rcm->id, rcm->seq_n);
      printfflush();**/

      // Check if source id is valid
      if(id > MAX_MOTES-1){
        return bufPtr;
      }

      // Check if we already got a msg from it, if FALSE, initialize start_counter and last_counter
      if(start_counter[id] == -1){
        start_counter[id] = rcm->seq_n;
        last_counter[id] = rcm->seq_n;
      }
      // Otherwise we already got a msg from the mote
      else {
        // Check if we received a consecutive counter, if TRUE, increment last_counter
        if (last_counter[id] == rcm->seq_n -1){
          last_counter[id]++;
        }
        // Otherwise it means we missed a msg, then we reset the start_counter and last_counter
        else{
          start_counter[id] = rcm->seq_n;
          last_counter[id] = rcm->seq_n;
        }
      }

      // Now check if this was the 10th consecutive msg, if TRUE, send an alert and reset start_counter
      if(last_counter[id] - start_counter[id] >= 10){
        printf("[%u] Too close to >%u<\n", TOS_NODE_ID, rcm->id);
        printfflush();
        start_counter[id] = last_counter[id];
      }


    }
      
      return bufPtr;
  }


  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    if (&packet == bufPtr) {
      locked = FALSE;
    }
  }

}