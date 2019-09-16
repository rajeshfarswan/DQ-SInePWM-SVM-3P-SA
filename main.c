//************************************************************//
// STAND ALONE THREE PHASE INVERTER BASED ON SPACE VECTOR PWM //          //
//************************************************************//

//include files
#include "main.h"
#include "user.h"
#include "asmMath.h"

int main(void) //main
{

init();  // call processor initilisation code

starting(); // Before-PWM initiliasation and soft-start of system

  while(1) //main loop 
	{

//current control//
    if(current_Flag) //20Khz
       {     
           
          asm("disi #0x3FFF"); //read inverter currents
           {
            Avalue = asmADC(0x0008) - offset; //adc channel 8 
            Bvalue = asmADC(0x0009) - offset; //adc channel 9
            Cvalue = asmADC(0x000A) - offset; //adc channel 10
           } 
          asm("disi #0x0000");
           //
           //detect peak current generate if fault
          if(Avalue > current_max) fault_Flag = 0; 
          if(Bvalue > current_max) fault_Flag = 0;
          if(Cvalue > current_max) fault_Flag = 0;  

          if(Avalue < current_min) fault_Flag = 0;  
          if(Bvalue < current_min) fault_Flag = 0;
          if(Cvalue < current_min) fault_Flag = 0; 
           // 

			asmABCtoDQ(); //converter feedback currents a-b-c to dq frame
        
            //current D PI //voltage PI D output is current ref
            IPreError = currentP_Dout;
            currentP_Dout = asmPIcontroller(Vd_FOFout,Dvalue,current_Pgain,current_Igain);

            Dvalue = currentP_Dout; 

            //current Q PI
            IPreError = currentP_Qout;
            currentP_Qout = asmPIcontroller(Vq_FOFout,Qvalue,current_Pgain,current_Igain);

            Qvalue = currentP_Qout;

            asmDQtoAB(); //current d-q PI output to two phase refs

            asmSVM(); //generate svm duty cycle from two phase refs  
            
                               current_Flag = 0;   
                                  } 
//current control//

//Inverter output voltage control//          
	if(pll_Flag) //12Khz _PLL_count
		{
          asm("disi #0x3FFF"); //read inverter output voltages
           {
          Avalue = asmADC(0x0005) - offset; //adc channel 5  
          Bvalue = asmADC(0x0006) - offset; //adc channel 6    
          Cvalue = asmADC(0x0007) - offset; //adc channel 7
            } 
          asm("disi #0x0000");
          //

          asmABCtoDQ(); //three phase to d-q voltage feedbacks

          /*voltage D PI******************************************************/
          IPreError = Vd_PI_out;
          Vd_PI_out = asmPIcontroller(V_Dref,Dvalue,vPI_Pgain,vPI_Igain);
           
         /*voltage Q PI******************************************************/
          IPreError = Vq_PI_out;
          Vq_PI_out = asmPIcontroller(0,Qvalue,vPI_Pgain,vPI_Igain);
             
          //voltage D PI filter
          FOF_PreOut = Vd_FOFout;
          Vd_FOFout = asmFO_Filter(Vd_PI_out,Filter_const_V); //this is current d-ref

          //voltage Q PI filter
          FOF_PreOut = Vq_FOFout;
          Vq_FOFout = asmFO_Filter(Vq_PI_out,Filter_const_V); //this is current q-ref
         
				         pll_Flag = 0;
						  }
//voltage control//	


//DC link monitoring and soft start//
		if(ffd_Flag) //0.5Khz   
      		{  
              asmDClink(); //monitor dc link
              SET = 0x0077; //all three switces are enabled

              V_Dref++; //initiate soft start of inverter output voltage

                   if(V_Dref >= V_Dsetpoint)
                       { 
                         V_Dref = V_Dsetpoint; //set inverter voltage ref
                           
                        }            
       		                    ffd_Flag = 0;
       							}
//soft start end//

    			ClrWdt();
    		}//while end////////////////////////////////////////////////////////

  
		ClrWdt();
	} //main end////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////


//T1 interrupt for oscillator tracking
		void _ISRFAST __attribute__((interrupt, no_auto_psv)) _T1Interrupt(void) //99.88Khz
  			{   
                
                if(osc_Flag)//7.5Khz
                 {
                  //harmonic oscillator for generating Sine and Cos ref. 

                  OSC_F = OSC_Fcentral;   //set inverter frequency 50 Hz
                 
                  theta = theta + OSC_F;  //increment theta angle
     
         		    if(theta >= theta_2PI) //reset harmonic oscillator
            		    {
           				qSin = 0;
           				qCos = 32440; //0.99
           				theta = 0;
              				}
              					else asmHARMONIC(); //harmonic oscillator

                      osc_Flag = 0;
                      } 
                
     			T1us_Flag = 0;
                
   					} //T1 interupt end

///////////////////////////////////////////////////////////////////////

		//fault interrupt
		void _ISR __attribute__((interrupt, no_auto_psv)) _FLTBInterrupt(void)
  			 {
     			PWMenable = 0; //disable pwm
     			SET = 0;       //all switches off
          
     			RL2_ON = 0;    //open all relays
               
     			RL3_ON = 0;      
     			RL4_ON = 0; 
     			RL5_ON = 0;     
  
		fault_Flag = 0; 
            
   			}//fault end

//////////////////////////////////////////////////////////////////////

		    //initial startup routine before turning on PWM

			void starting(void)
  				{
                    PWM_offset = PWM_PERIOD; //initialise PWM period value
                    PWM_offset_N = -PWM_PERIOD;

					PWM_max = PWM_offset*8; //PI saturation values
					PWM_min = -PWM_offset*8;
					SET = 0;               //initialise PWM control registers
					PWMenable = 0;         //reset PWM control register
					 //
					FAULT_ENABLE = 1; //0x000f; //reset fault register
					delay(30); //delay 30ms
					ADC_ON = 1;
					//precharging init
					RL1_ON = 1;  //precharging enable
					delay(15); //delay 1500ms
					//precharging init ends
					
					offset = asmADC(0x0e0e); //2.5V offset //read adc channel 14
					//
					//initiates startup
					RL1_ON = 0;  //precharging disable
					delay(30); //delay 30ms
					RL2_ON = 1;  //bypass precharging
					delay(30); //delay 30ms
					
					//set pwm
					PWM1 = PWM_offset;
					PWM2 = PWM_offset;
					PWM3 = PWM_offset;
				
					PWMenable = 1; //pwms and all timers enabled
					T1ON = 1;
                    T2ON = 1;
                    T3ON = 1;
                    T4ON = 1;
                    T5ON = 1;
                    
					// 
					  	}//startup routine end

///////////////////////////////////////////////////////////////////////

			











