/**
 *  @author Federico Di Cesare	10529764
 *  @author Luca Giacometti		10524482
 */

#include "keepYourDistance.h"
#include "Timer.h"
#include "printf.h"
#define MAX_LENGTH 100
#define MAX_CONSECUTIVE_MSG 10

module keepYourDistanceC {

  uses {
  
  /****** INTERFACES *****/
	interface Boot; 
	
    //interfaces for communication
    interface SplitControl;
	interface Packet;
    interface AMSend;
    interface Receive;
    
	//interface for timer
	interface Timer<TMilli> as SenderTimer;
	//interface Timer<TMilli> as ReceiverTimer;
	
    //other interfaces, if needed
    interface PacketAcknowledgements as PAck;
	
  }

} implementation {

  // the number of consecutive packet with the same mote_id
  uint16_t counter_received = 0;
  
  message_t packet;
  bool locked;

  // this is the array which contains the last MAX_LENGTH mote_ids received
  // to keep trace of the last 10 ids for sending the alarm message
  // it follows a FIFO policy
  // the mote_ids are inserted from the 0 to (MAX_LENGTH - 1)
  uint8_t rec_id[MAX_LENGTH];

  void sendReq();
  void handleTheMessage(uint8_t mote_id);
  
  
  //***************** Support function ********************//
  void insert(uint8_t mote_id) {
  	// the insertion of the mote_id inside the array is handled here
  	
  }
  
  
  //***************** Send request function ********************//
  void sendReq() {
	/* This function is called when we want to send a request
	 *
	 * STEPS:
	 * 1. Prepare the msg
	 * 2. Set the ACK flag for the message using the PacketAcknowledgements interface
	 *     (read the docs)
	 * 3. Send an BROADCAST message with the id inside it
	 * X. Use debug statements showing what's happening (i.e. message fields)
	 */
	 
      keepyourdistance_msg_t* mess = (keepyourdistance_msg_t*)(call Packet.getPayload(&packet, sizeof(keepyourdistance_msg_t)));
	  if (mess == NULL) {
		return;
	  }
	  dbg("radio_pack","Preparing the message... \n");
	  // setting the ID of the mote
	  mess->id = TOS_NODE_ID;
	  //setting the ACK	  
	  call PAck.requestAck(&packet);
	  
	  //BROADCAST message + some debugging
	  if(call AMSend.send( AM_BROADCAST_ADDR,&packet, sizeof(keepyourdistance_msg_t)) == SUCCESS){
	     dbg("radio_send", "Packet passed to lower layer successfully!\n");
	     dbg("radio_pack",">>>Pack\n \t Payload length %hhu \n", call Packet.payloadLength( &packet ) );
	     dbg_clear("radio_pack","\t Payload Sent\n" );
		 dbg_clear("radio_pack", "\t\t value: %hhu \n", mess->value);
		 
  	  }
  	  
 }        

  //****************** Task send response *****************//
  void handleTheMessage(uint8_t mote_id) {
  	/* This function is called when we receive a message.
  	 * We need to update the data inside the rec_id and the counter_received
  	 * and then handle the sending of the message to node-red
  	 */
  	 
  	 insert(mote_id);
  	 
  	 if (rec_id[0] == rec_id[1]) {
  	 	// there is another consecutve message from the same mote_id
  	 	counter_received++;
  	 	if (counter_received == 10) {
  	 		// the alarm message is triggered
  	 		// we need to prompt it to cooja and send towards socket to node-red
  	 		// the message contains:
  	 		// - the id of the mote which received the MAX_CONSECUTIVE_MSG messages
  	 		// - the id of the mote which the message are from
  	 		dbg("trigger_message", "The trigger message is raised!\n");
  	 	}
  	 	
  	 }
  	 else {
  	 	// the sequence of same mote_id is cut so a new one is starting
  	 	counter_received = 1;
  	 }
  }

  //***************** Boot interface ********************//
  event void Boot.booted() {
	dbg("boot","Application booted on node %u.\n", TOS_NODE_ID);
	call SplitControl.start();
  }

  //***************** SplitControl interface ********************//
  event void SplitControl.startDone(error_t err){
    
    if(err == SUCCESS) {
    	dbg("radio", "Radio on!\n");
    	// in the specification document is written 500 ms
        call SenderTimer.startPeriodic( 500 );
    }
    else{
		dbgerror ("radio", "Trying again to start the radio!\n");
		call SplitControl.start();
    }
    
  }
  
  event void SplitControl.stopDone(error_t err) {}

  //***************** MilliTimer interface ********************//
  event void SenderTimer.fired() {
	/* This event is triggered every time the timer fires.
	 * When the timer fires, we send a request
	 */
	dbg("timer","Sender timer fired at %s.\n", sim_time_string());
	sendReq();
  }

  //********************* AMSend interface ****************//
  event void AMSend.sendDone(message_t* buf,error_t err) {
	/* This event is triggered when a message is sent 
	 *
	 * STEPS:
	 * 1. Check if the packet is sent
	 * 2. Check if the ACK is received (read the docs)
	 * 2a. If yes, do nothing to send again the message
	 * 2b. Otherwise, do nothing to send again the message
	 * X. Use debug statements showing what's happening (i.e. message fields)
	 */
	 if (&packet == buf && err == SUCCESS) {
     	dbg("radio_send", "Packet sent...");
     	dbg_clear("radio_send", " at time %s \n", sim_time_string());
     	if (call PAck.wasAcked(buf)) {
     		// doing nothing
     		dbg("radio_send", "Packet acked...");
     	}
     	else {
     		// doing nothing
     		dbg("radio_send", "Packet not acked...");
     	}
     }
     else{
     	dbgerror("radio_send", "Send done error!");
     }
	 
  }

  //***************************** Receive interface *****************//
  event message_t* Receive.receive(message_t* buf,void* payload, uint8_t len) {
	/* This event is triggered when a message is received 
	 *
	 * STEPS:
	 * 1. Read the content of the message
	 * 2. Check if the type is request (REQ)
	 * 3. If a request is received, send the response
	 * X. Use debug statements showing what's happening (i.e. message fields)
	 */
	if (len != sizeof(keepyourdistance_msg_t)) {return buf;}
    else {
      keepyourdistance_msg_t* mess = (keepyourdistance_msg_t*)payload;
      
      dbg("radio_rec", "Received packet at time %s\n", sim_time_string());
      dbg("radio_pack"," Payload length %hhu \n", call Packet.payloadLength( buf ));
      dbg("radio_pack", ">>>Pack \n");
      dbg_clear("radio_pack","\t\t Payload Received\n" );
	  dbg_clear("radio_pack", "\t\t value: %hhu \n", mess->value);
      
      handleTheMessage(mess->id);
      
      return buf;
    }
    {
      dbgerror("radio_rec", "Receiving error \n");
    }
  }

}

