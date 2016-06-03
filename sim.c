// COS 375: PAW Instruction Set
// Group: Terrence Kuo, Haley Chow, Natalia Perina, Conor McGrory
// Compile: gcc -g -o sim sim.c -lxcb
// Run: ./sim <some binary file>

#include <stdio.h>
#include "../mmio.h"
#include "../statedumper.h"

/* PC is register 15, and FLAGS is register 16 */
enum {PC = 15, FLAGS = 16}; 

void formatZero(unsigned char OP, int* GeneralRegs);

void formatThree(unsigned char OP, unsigned char Rd, unsigned char Imm8, 
                 int* GeneralRegs);

void formatFour(unsigned char OP, unsigned char Rs, unsigned char Rd, 
                int* GeneralRegs);

void formatFive(unsigned char OP, unsigned char H1, unsigned char Rs, 
                unsigned char Rd, int* GeneralRegs);

void formatNine(unsigned char B, unsigned char L, unsigned char Imm5,
                unsigned char Rb, unsigned char Rd, int* GeneralRegs,
                unsigned char* Memory);

void formatTwelve(unsigned char SP, unsigned char Rd, unsigned char Imm8,
                  int* GeneralRegs);

void formatSixteen(unsigned char Cond, char Offset, int* GeneralRegs);

void setStatusReg(unsigned int val, int* GeneralRegs);

void setCFlag(unsigned char Rs, unsigned char Rd, unsigned char Imm8, 
                  unsigned char op, int* GeneralRegs);

void setVFlag(unsigned char Rs, unsigned char Rd, unsigned char Imm8, 
                unsigned char add, int* GeneralRegs);


int main(int argc, char *argv[]){
   
   /* 17 general registers - represented as 32-bit unsigned ints */
   int * GeneralRegs;
   GeneralRegs = (int*) malloc(17*sizeof(int));

   /* 2^16 byte memory - represented as unsigned chars */
   unsigned char * Memory;
   Memory = (unsigned char*) malloc(65536*sizeof(int));
    
   /* Initialize monitor */
   struct monitor mn = Initialize_Monitor(Memory);

   /* Try to read binary file into memory */
   FILE *fr; // file pointer
   int numOfBytes;
   if (sizeof(argv) != 2)
   {
      /* Try to open binary file */
      fr = fopen(argv[1], "r"); 
      
      /* If fr is non-null, read file into memory */
      if (fr)
      {
         numOfBytes = 0;
         while (!feof(fr)) // while not EOF
         {
            fread(&Memory[numOfBytes], 1, 1, fr); //read byte by byte
            numOfBytes++;
         }

         fclose(fr);

      }
      /* Otherwise, print error message */
      else 
      {
         fprintf(stderr, "Unable to read file\n");
         exit(1);
      }
   }
   else
   {
      fprintf(stderr, "No filename provided\n");
      exit(1);
   }
   
   /* Now that the memory is initialized, execute the instructions */
   int instructEncoding;   
   GeneralRegs[PC] = 0; // set PC to first instruction

   while(1){
      Update_Monitor(mn, Memory); // update monitor
      
      // concat the two bytes in Memory to form an instruction set
      unsigned char lowerByte = Memory[GeneralRegs[PC]];
      unsigned char upperByte = Memory[GeneralRegs[PC]+1];
      int instruction = lowerByte | (upperByte << 8);
             
      // determine Instruction Set Encoding
      if ((upperByte >> 5) == 0)
         instructEncoding = 0;
      if ((upperByte >> 5) == 1)
         instructEncoding = 3;
      if ((upperByte >> 2) == 16)
         instructEncoding = 4;
      if ((upperByte >> 2) == 17)
         instructEncoding = 5;
      if ((upperByte >> 5) == 3)
         instructEncoding = 9;
      if ((upperByte >> 4) == 10)
         instructEncoding = 12;
      if ((upperByte >> 4) == 13)
         instructEncoding = 16;

      /*
        Based on the type of Instruction Encoding,
        a corresponding function will be called. 
        The corresponding function will determine the instruction type
      */
      switch (instructEncoding) {
         unsigned char OP, Rb, Rd, Rs, Imm8, Imm5, H1, B, L, SP, cond, offset;
         
         case 0:
            OP = (upperByte & 0x1f);//upperByte & 00011111
            formatZero(OP, GeneralRegs);
            
            free(GeneralRegs);
            free(Memory);
            return 0;
            
         case 3:
            OP = (upperByte & 0x18) >> 3; //b101000
            Rd = (upperByte & 0x7);
            Imm8 = (lowerByte);
            formatThree(OP, Rd, Imm8, GeneralRegs);
            break;
            
         case 4:
            OP = (instruction & 0x3c0) >> 6; // b1111000000
            Rs = (instruction & 0x38) >> 3; // b111000
            Rd = (instruction & 0x7); // b111 
            formatFour(OP, Rs, Rd, GeneralRegs);
            break;

         case 5:
            OP = (instruction & 0x300) >> 8; // b1100000000
            H1 = (instruction & 0x80) >> 4; // b10000000
            Rs = (instruction & 0x78) >> 3; // b1111000
            Rd = (instruction & 0x7); // b111 
            Rd = Rd | H1;
            formatFive(OP, H1, Rs, Rd, GeneralRegs);
            break;

         case 9:
            B = (instruction & 0x1000) >> 12; // b1000000000000
            L = (instruction & 0x800) >> 11; // b100000000000
            Imm5 = (instruction & 0x7C0) >> 6; // b11111000000
            Rb = (instruction & 0x38) >> 3; // b111000
            Rd = (instruction & 0x7); //b111
            formatNine(B, L, Imm5, Rb, Rd, GeneralRegs, Memory);
            break;

         case 12:
            SP = (instruction & 0x800) >> 11; // b100000000000
            Rd = (instruction & 0x700) >> 8; //b 11100000000
            Imm8 = (instruction & 0xFF); // b11111111
            formatTwelve(SP, Rd, Imm8, GeneralRegs);
            break;

         case 16:
            cond = (instruction & 0xF00) >> 8; // b111100000000
            offset = (instruction & 0xFF); //b11111111
            formatSixteen(cond, offset, GeneralRegs);
            break;

         default:
            fprintf(stderr, "Illegal operation in instructEncoding\n");
            exit(1);
      }
    }
    
    free(Memory);
    free(GeneralRegs);
    
    return 0;
}

/*
  Below are the corresponding functions to determine
  the instruction type
*/
void formatZero(unsigned char OP, int* GeneralRegs){
   /* If OP is not zero, print error message and exit */
   if (OP != 0) 
   {
      fprintf(stderr, "Illegal operation in formatZero\n");
      exit(1);
   }

   /* Print out the values of all registers */
   /*
   int i;
   printf("\nRegister Values:\n");
   for(i = 0; i<17; i++)
   {
      printf("Reg %d: %x\n",i, GeneralRegs[i]); 
   }
   */

   exit(0);
}

void formatThree(unsigned char OP, unsigned char Rd, unsigned char Imm8, 
                 int* GeneralRegs)
{
   unsigned char instructType = OP;
   unsigned int alu_out;
   
   switch(instructType){

      case 0: // MOV IMMEDIATE
         GeneralRegs[Rd] = Imm8;
         setStatusReg(GeneralRegs[Rd], GeneralRegs); //NZ
         break;

      case 1: // CMP IMMEDIATE
         setCFlag(0, Rd, Imm8, 2, GeneralRegs);
         setVFlag(0, Rd, Imm8, 1, GeneralRegs);
         alu_out = GeneralRegs[Rd] - Imm8;
         setStatusReg(alu_out, GeneralRegs);
         break;

    default:
       fprintf(stderr, "Illegal operation in formatThree\n");
       exit(1);
  }

   /* Set PC to next instruction */
   GeneralRegs[PC] = GeneralRegs[PC] + 2;
}

void formatFour(unsigned char OP, unsigned char Rs, unsigned char Rd, 
                int* GeneralRegs)
{
  unsigned char instructType = OP;
  int alu_out; 

  switch(instructType){

     case 0: // AND
        // Bitwise and 
        GeneralRegs[Rd] = GeneralRegs[Rd] & GeneralRegs[Rs];
        setStatusReg(GeneralRegs[Rd], GeneralRegs); 
        break;
        
     case 1: // EOR
        GeneralRegs[Rd] = GeneralRegs[Rd] ^ GeneralRegs[Rs]; 
        setStatusReg(GeneralRegs[Rd], GeneralRegs);
        break;

     case 2: // ASR
        if (GeneralRegs[Rs] == 0)
        {
           break; 
        }
        // if lower rs[7:0] < 16 
        else if ((GeneralRegs[Rs] & 0xFF) < 16) 
        {
           setCFlag(Rs, Rd, 0, 1, GeneralRegs);
           GeneralRegs[Rd] = GeneralRegs[Rd] >> GeneralRegs[Rs];
        }
        else 
        {
           // if Rd[15] == 0 then rd = 0 
           if (GeneralRegs[Rd] & (1 << 15) == 0)
              GeneralRegs[Rd] = 0; 
           else 
              GeneralRegs[Rd] = 0xffff; 
        }

        setStatusReg(GeneralRegs[Rd], GeneralRegs);
        break; 

    case 3: // TST
      alu_out = GeneralRegs[Rd] & GeneralRegs[Rs];
      setStatusReg(alu_out, GeneralRegs); 
      break;

     case 4: // NEG
        setCFlag(Rs, 0, 0, 3, GeneralRegs);
        setVFlag(Rs, 0, 0, 3, GeneralRegs);
 
        /* Raw difference */
        alu_out  = 0 - GeneralRegs[Rs]; 
        /* Mask the top 16 bits */
        GeneralRegs[Rd] = alu_out & 0xFFFF;

        setStatusReg(GeneralRegs[Rd], GeneralRegs);
        break;

    case 5: // CMP
      setCFlag(Rs, Rd, 0, 2, GeneralRegs);
      setVFlag(Rs, Rd, 0, 1, GeneralRegs); //cmp is one for vFlag 
      alu_out = GeneralRegs[Rd] - GeneralRegs[Rs]; 
      setStatusReg(alu_out,  GeneralRegs); 
      break;
    default: 
      fprintf(stderr, "Illegal operation in formatFour\n");
      exit(1);
  }

   /* Set PC to next instruction */
  GeneralRegs[PC] = GeneralRegs[PC] + 2;
}

void formatFive(unsigned char OP, unsigned char H1, unsigned char Rs, 
                unsigned char Rd, int* GeneralRegs)
{
   int alu_out; 
   switch(OP)
   {
      /* ADD */
      case 0: 
         /* Set C and V flags */
         setCFlag(Rs, Rd, 0, OP, GeneralRegs); 
         setVFlag(Rs, Rd, 0, OP, GeneralRegs); 

         /* Compute raw sum of Rd and Rs */
         alu_out = GeneralRegs[Rd] + GeneralRegs[Rs]; 
         
         /* Set bits 0-15 of Rd to bits 0-15 of alu_out */
         GeneralRegs[Rd] = (alu_out & 0xFFFF);

         /* Set bits 16-31 of Rd to bit 15 (sign bit) of alu_out */
         if (alu_out & 0x8000) 
            GeneralRegs[Rd] = (GeneralRegs[Rd] | 0xFFFF0000);

         /* Update N and Z flags */
         setStatusReg(GeneralRegs[Rd], GeneralRegs);
         break;

      case 1: // CMP
         /* Set C and V flags */
         setCFlag(Rs, Rd, 0, 2, GeneralRegs);
         setVFlag(Rs, Rd, 0, OP, GeneralRegs);

         /* Compute raw difference (32 bit signed int) of Rd and Rs */
         alu_out = GeneralRegs[Rd] - GeneralRegs[Rs];

         /* Pass this raw difference to setStatusReg */
         setStatusReg(alu_out, GeneralRegs); 
         break;

      case 2: //MOV
         /* Hansen: mov r15 incorrect
          * mov r15,r1 should override pc+2*/
         GeneralRegs[Rd] = GeneralRegs[Rs];
         setStatusReg(GeneralRegs[Rd], GeneralRegs);
         if (Rd == PC)
            GeneralRegs[Rd] = GeneralRegs[Rd] - 2;
         break;

      default: 
         fprintf(stderr, "Illegal operation in formatFive\n");
         exit(1);
   }

   GeneralRegs[PC] = GeneralRegs[PC] + 2;
}

void formatNine(unsigned char B, unsigned char L, unsigned char Imm5, 
                unsigned char Rb, unsigned char Rd, int* GeneralRegs,
                unsigned char* Memory) 
{
  /* Use B and L to determine which instruction we have */
  unsigned char instructType = ((B & 0x01) << 1) | (L & 0x01);

  /* Convert value stored in Rb to an unsigned int (for addressing) */
  unsigned int RbVal = (unsigned int) GeneralRegs[Rb];
  
  switch (instructType){
    unsigned int addr;
    unsigned char lo;
    unsigned char hi;

    case 0: // STR
      /* Compute address */
      addr = (RbVal & 0xFFFC) + (Imm5 << 2);
      
      /* Extract low and high bytes from Rd */
      lo = GeneralRegs[Rd] & 0x00FF;
      hi = (GeneralRegs[Rd] & 0xFF00) >> 8;
      
      /* Store both bytes in memory (in order) */
      Memory[addr] = lo;
      Memory[addr + 1] = hi;

      break;
      
    case 1: // LDR
       /* Compute address -- must be divisible by 4 */
      addr = (RbVal & 0xFFFC) + (Imm5 << 2);

      /* Check read from keyboard */
      if (addr == 0xb000)
      {
         GeneralRegs[Rd] = (int) Read_Keyboard();
      }

      /* Combine bytes into halfword and store in Rd */
      else 
      {
         /* Load low and high bytes from memory */
         lo = Memory[addr];
         hi = Memory[addr + 1];

         GeneralRegs[Rd] = (int) ((hi << 8) | lo);
      }

      break;

    case 2: //STRB
      /*Need to mask the first 16 bits of Rbval*/
      RbVal = RbVal & 0xFFFF; 

      /* Compute address */
      addr = RbVal + Imm5;
      
      /* Store low byte of Rd in memory */
      Memory[addr] = (0xFF & GeneralRegs[Rd]);

      break;

    case 3: //LDRB
      /*Need to mask the first 16 bits of Rbval*/
      RbVal = RbVal & 0xFFFF; 
      
      /* Compute address */
      addr = RbVal + Imm5;

      /*Check read from keyboard*/
      if (addr == 0xb000)
      {
         GeneralRegs[Rd] = (int) Read_Keyboard();
      }
      /* Load byte at addr to register Rd */
      else
      {
         GeneralRegs[Rd] = (int) Memory[addr];
      }

      break;
  }

  GeneralRegs[PC] = GeneralRegs[PC] + 2;
}

void formatTwelve(unsigned char SP, unsigned char Rd, unsigned char Imm8,
                  int* GeneralRegs)
{
  /* If SP != 0, then no instruction is specified */
  if (SP){
    fprintf(stderr, "Illegal operation in formatTwelve\n");
    exit(1);
  }

  /* If SP == 0, then instruction is ADD(2) */
  /*Hansen: computation incorrect
   * shoud be FFFC instead of FFFE*/
  GeneralRegs[Rd] = (GeneralRegs[PC] & 0xFFFC) + (Imm8 << 2);
  
  GeneralRegs[PC] = GeneralRegs[PC] + 2;
}

void formatSixteen(unsigned char Cond, char Offset, int* GeneralRegs)
{
  unsigned char encoding = Cond;
  int s_extended = (int) (Offset << 1);
  int flag = GeneralRegs[FLAGS];

  switch (encoding){ 

    // EQ, equal, Z = 1
     case 0:   
        if (flag & 0x4) //b01
        {
           GeneralRegs[PC] = GeneralRegs[PC] + s_extended;
           return;
        }
        break; 
        
        // NE, not equal, Z = 0
     case 1:  
        if (!(flag & 0x4))
        {
           GeneralRegs[PC] = GeneralRegs[PC] + s_extended;
           return;
        }
        break; 
        
        // CS, carry set, unsigned higher or same, C = 1
     case 2:  
        if (flag & 0x2)
        {
           GeneralRegs[PC] = GeneralRegs[PC] + s_extended;
           return;
        }
        break; 

        // CC, Carry clear/ unsigned lower, C = 0   
     case 3:  
        if (!(flag & 0x2))
        {
           GeneralRegs[PC] = GeneralRegs[PC] + s_extended;
           return;
        }
        break; 
        
        // MI, Minus/Negative, N = 1  
     case 4:  
        if (flag & 0x8) 
        {
           GeneralRegs[PC] = GeneralRegs[PC] + s_extended;
           return;
        }
        break; 
        
        // PL, Plus/Positive or Zero, N = 0   
     case 5:  // PL, Plus/Positive or Zero, N = 0 
        if (!(flag & 0x8))
        {
           GeneralRegs[PC] = GeneralRegs[PC] + s_extended;
           return;
        }
        break;
        
        // VS, overflow , V = 1/                                   
     case 6:  
        if (flag & 0x1)
        {
           GeneralRegs[PC] = GeneralRegs[PC] + s_extended;
           return;
        }
        break; 
        
        // VC, no overflow, V =0 
     case 7: 
        /* Hansen: bvc incorrect
         * shoudl be & 0x1 instead of * 0x8*/
        if (!(flag & 0x1))
        {
           GeneralRegs[PC] = GeneralRegs[PC] + s_extended;
           return;
        }
        break; 
        
        // HI, unsigned higher, C = 1 && Z = 0 
     case 8: 
        if ((flag & 0x2) && (!(flag & 0x4)))
        {
           GeneralRegs[PC] = GeneralRegs[PC] + s_extended;
           return;
        }
        break;
        
        // LS, unsigned lower or same, C = 0 || Z = 0 
     case 9: 
        if (!(flag & 0x2) || !(flag & 0x4))
        {
           GeneralRegs[PC] = GeneralRegs[PC] + s_extended;
           return;
        }
        break; 
        
        // GE, signed >=, N == V  
     case 10: // GE, signed >=, N == V
        if ((flag & 0x8) >> 3 == (flag & 0x1))
        {
           GeneralRegs[PC] = GeneralRegs[PC] + s_extended;
           return;
        }
        break;
        
        // LT, signed <, N != V    
     case 11: 
        if (((flag & 0x8) >> 3) != (flag & 0x1))
        {
           GeneralRegs[PC] = GeneralRegs[PC] + s_extended;
           return;
        }
        break; 
        
        // GT, signed >, Z = 0 && ( N == V) 
     case 12: 
        if (((flag & 0x8) >> 3 == (flag & 0x1)) && !(flag & 0x4))
        {
           GeneralRegs[PC] = GeneralRegs[PC] + s_extended;
           return;
        }
        break;
        
        // LE, signed <=, Z = 1 || (N != V)
     case 13: 
        /* Hansen: ble incorrect
         * should be || instead of && here */
        if (((flag & 0x8) >> 3 != (flag & 0x1)) || (flag & 0x4))
        {
           GeneralRegs[PC] = GeneralRegs[PC] + s_extended;
           return;
        }
        break; 
  }
  
  /* If we haven't returned by this point, all of the above if conditions 
   * have been false */
  GeneralRegs[PC] = GeneralRegs[PC] + 2;
}

// some instructions type do not need the cFlag or the vFlag
void setStatusReg(unsigned int val, int* GeneralRegs)
{
  unsigned char flag;
  // N Flag
  // obtain MSB
  
  flag = (val & 0x8000) >> 15; // b1000000000000000 
  if (flag == 0)
    GeneralRegs[16] = GeneralRegs[16] & 0xFFF7; // b1111111111111011
  else
    GeneralRegs[16] = GeneralRegs[16] | 0x8; // b0000000000000100
  unsigned char nFlag = (GeneralRegs[16] & 0x8) >> 3 ;

  // Z Flag
  if (val == 0)
    GeneralRegs[16] = GeneralRegs[16] | 0x4; // b0000000000000100
  else
    GeneralRegs[16] = GeneralRegs[16] & 0xFFFB; // b1111111111111011
}

void setCFlag(unsigned char Rs, unsigned char Rd, unsigned char Imm8,
        unsigned char op, int* GeneralRegs)
{
  //unsigned long sum;
  unsigned int sum;
  unsigned int valRd;
  unsigned int valRs;
  unsigned int valImm8;
  int svalImm8;
  int svalRs;
  unsigned char shiftAmt;
  unsigned char cFlag;
  unsigned int shiftedVal;
  
  valRd = GeneralRegs[Rd] & 0xffff; //get the bottom 16 bits
  
  if (op == 0) { //add
    valRs = GeneralRegs[Rs] & 0xffff;
    sum = valRd + valRs;
    cFlag = (sum & 0x0001FFFF) >> 16; //take the 17th bit as carry flag 
  }
    
  if (op == 1) { //shift
    shiftAmt = GeneralRegs[Rs] & 0xff;
    if (shiftAmt < 16) 
      shiftedVal = GeneralRegs[Rd] >> ((GeneralRegs[Rs] & 0xff)-1);
    else 
      shiftedVal = GeneralRegs[Rd] >> 15;
    cFlag = shiftedVal & 0x1; //b0000000000000001
  }
  
  if (op == 2) { //compare
    if (Imm8 != 0) {
      svalImm8 = ~Imm8; //sign extend the negation
      valImm8 = svalImm8 & 0xffff; //want the last 16 bits of the signextended Imm8
      sum = valRd + valImm8 + 1;
    }
      
    else
    {
      svalRs = ~GeneralRegs[Rs];
      valRs = svalRs & 0xffff;
      sum = valRd + valRs + 1;
    }
    cFlag = (sum & 0x0001FFFF) >> 16; 
  }

  if (op == 3) { //neg
    svalRs = ~GeneralRegs[Rs];
    valRs = svalRs & 0xffff;
    sum = 0 + valRs + 1;
    cFlag = (sum & 0x0001FFFF) >> 16;
  }
 
  if (cFlag == 1)
    GeneralRegs[16] = GeneralRegs[16] | 0x2; //b0000000000000010
  else 
    GeneralRegs[16] = GeneralRegs[16] & 0xFFFD; //b1111111111111101

}

void setVFlag(unsigned char Rs, unsigned char Rd, unsigned char Imm8,
        unsigned char op, int* GeneralRegs)
{
    unsigned char vFlag = 0;
    unsigned char signBitOne;
    unsigned char signBitTwo;
    unsigned int sum;

    signBitOne = GeneralRegs[Rd] >> 15; //get the first bit of each value
    if (op == 0){ //add
      signBitTwo = GeneralRegs[Rs] >> 15;
      if (signBitOne == signBitTwo) { //check if sign bits are the same
        sum = GeneralRegs[Rd] + GeneralRegs[Rs];
        if (signBitOne != sum >> 15) //set vFlag if the sum's sign bit is different
          vFlag = 1;
      }
    }

    else if (op == 1) { //cmp, with/without immediate
      if (Imm8 == 0)
        signBitTwo = (-GeneralRegs[Rs]) >> 15;
      else 
        signBitTwo = (-Imm8) >> 7; //immediate is 8 bits
      if (signBitOne == signBitTwo) { 
        sum = GeneralRegs[Rd] - GeneralRegs[Rs];
        if (signBitOne != sum >> 15) //set vFlag if the sum's sign bit is different
          vFlag = 1;
      }
    }

    else { //neg
      signBitTwo = (-GeneralRegs[Rs]) >> 15;
      if (signBitOne == signBitTwo &&  signBitOne != 0) { 
        sum = 0 - GeneralRegs[Rs];      
        /*Hansen: V flag incorrect
         * V=1 when sign rs = sign rd != 0*/ 
        if (signBitOne != sum >> 15) //set vFlag if the sum's sign bit is different
            vFlag = 1;
      }
    }

    if (vFlag == 1)
      GeneralRegs[16] = GeneralRegs[16] | 0x1; //b0000000000000001
    else 
      GeneralRegs[16] = GeneralRegs[16] & 0xFFFE; //b1111111111111110
  }
