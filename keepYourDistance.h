/**
 *  @author Federico Di Cesare	10529764
 *  @author Luca Giacometti		10524482
 */

#ifndef KEEPYOURDISTANCE_H
#define KEEPYOURDISTANCE_H

//payload of the msg
typedef nx_struct keepyourdistance_msg {
	
	// the id of the mote which is propagating the message
	nx_uint8_t id;
	
} keepyourdistance_msg_t;

#define REQ 1
#define RESP 2 

enum{
	AM_KEEPYOURDISTANCE_MSG = 6,
};

#endif
