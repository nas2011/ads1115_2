import binary
import math
import serial.device as serial
import serial.registers as serial

DEFAULT-I2C-ADDRESS ::= 0x48
ALT-I2C-ADDRESS::= 0x49
REGISTER-CONVERT ::= 0x00
REGISTER-CONFIG ::= 0x01
REGISTER-LOWTHRESH::= 0x02
REGISTER-HITHRESH::= 0x03

CONVERT-READY-LO ::= 0x0000
CONVERT-READY-HI ::= 0x8000

OS-STARTCONV::= 0x8000  // Write: Set to start a single-conversion.
OS-CONTINUOUS ::= 0x0000


REGISTER-MASK_::= 0x03


OS-MASK_::= 0x8000

OS-BUSY_::= 0x0000    // Read: Bit=0 when conversion is in progress.
OS-NOTBUSY_::= 0x8000 // Read: Bit=1 when no conversion is in progress.


MUX-MASK_::= 0x7000
MUX-OPTS ::={
  "MUX-DIFF-0-1" : 0x0000,  // Differential P  =  AIN0, N  =  AIN1 (default).
  "MUX-DIFF-0-3" : 0x1000,  // Differential P  =  AIN0, N  =  AIN3.
  "MUX-DIFF-1-3" : 0x2000,  // Differential P  =  AIN1, N  =  AIN3.
  "MUX-DIFF-2-3" : 0x3000,  // Differential P  =  AIN2, N  =  AIN3.
  "MUX-SINGLE-0" : 0x4000,  // Single-ended AIN0.
  "MUX-SINGLE-1" : 0x5000,  // Single-ended AIN1.
  "MUX-SINGLE-2" : 0x6000,  // Single-ended AIN2.
  "MUX-SINGLE-3" : 0x7000,  // Single-ended AIN3.
}


SINGLE-ENDED_::= [MUX-SINGLE-0, MUX-SINGLE-1, MUX-SINGLE-2, MUX-SINGLE-3]

CPOL-MASK_::= 0x0008
CPOL-ACTVLOW_::= 0x0000  // ALERT/RDY pin is low when active (default).
CPOL-ACTVHI_::= 0x0008  // ALERT/RDY pin is high when active.

CLAT-MASK_::= 0x0004  // Determines if ALERT/RDY pin latches once asserted.
CLAT-NONLAT_::= 0x0000  // Non-latching comparator (default).
CLAT-LATCH_::= 0x0004  // Latching comparator.

CQUE-MASK_::= 0x0003
CQUE-1CONV_::= 0x0000  // Assert ALERT/RDY after one conversions.
CQUE-2CONV_::= 0x0001  // Assert ALERT/RDY after two conversions.
CQUE-4CONV_::= 0x0002  // Assert ALERT/RDY after four conversions.
// Disable the comparator and put ALERT/RDY in high state (default).
CQUE-NONE_::= 0x0003


FSR-MASK ::=   0x0E00
FSR-OPTS := {
  "FSR-6144" : 0x0000,  // +/-6.144V range  =  Gain 2/3.
  "FSR-4096" : 0x0200,  // +/-4.096V range  =  Gain 1.
  "FSR-2048" : 0x0400,  // +/-2.048V range  =  Gain 2 (default).
  "FSR-1024" : 0x0600,  // +/-1.024V range  =  Gain 4.
  "FSR-0512" : 0x0800,  // +/-0.512V range  =  Gain 8.
  "FSR-0256" : 0x0A00,  // +/-0.256V range  =  Gain 16.
}

FSR-VOLTS ::={
  "FSR-6144" : 6.144,
  "FSR-4096" : 4.096,
  "FSR-2048" : 2.048,
  "FSR-1024" : 1.024,
  "FSR-0512" : 0.512,
  "FSR-0256" : 0.256,
}


MODE-MASK_::=   0x0100
MODE-OPTS :={
  "MODE-CONTIN" : 0x0000,  // Continuous conversion mode.
  "MODE-SINGLE" : 0x0100,  // Power-down single-shot mode (default).
}


CMODE-MASK_::= 0x0010
COMP-OPTS ::={
  "CMODE-TRAD" : 0x0000,  // Traditional comparator with hysteresis (default).
  "CMODE-WINDOW" : 0x0010,  // Window comparator.
}

RATE-OPTS ::={
  "008-HZ" : 0x0000, // 8 samples per second.
  "016-HZ" : 0x0020, // 16 samples per second.
  "032-HZ" : 0x0040, // 32 samples per second.
  "064-HZ" : 0x0060, // 64 samples per second.
  "128-HZ" : 0x0080, // 128 samples per second (default).
  "250-HZ" : 0x00A0, // 250 samples per second.
  "475-HZ" : 0x00C0, // 475 samples per second.
  "860-HZ" : 0x00E0, // 860 samples per Second.
}



LSB-OPTS ::={
  "FSR-6114" : 0.0001875,
  "FSR-4096" : 0.000125, 
  "FSR-2048" : 0.0000625,
  "FSR-1024" : 0.00003125,
  "FSR-0512" : 0.000015625,
  "FSR-0256" : 0.000007815,
}


CHANNELS-MUX-SINGLE-0_::= [0, 0]
CHANNELS-MUX-SINGLE-1_::= [1, 0]
CHANNELS-MUX-SINGLE-2_::= [2, 0]
CHANNELS-MUX-SINGLE-3_::= [3, 0]
CHANNELS-MUX-DIFF-0-1_::= [0, 1]
CHANNELS-MUX-DIFF-0-3_::= [0, 3]
CHANNELS-MUX-DIFF-1-3_::= [1, 3]
CHANNELS-MUX-DIFF-2-3_::= [2, 3]


class Config:
  pga/int
  mode/int
  comp-mode/int
  rate/int
  convert-ms/int
  fsr/float
  lsb/float
  mux/int
  current-channel/int
  

  constructor.from-default :
    this.pga = FSR-OPTS["FSR-2048"]
    this.mode = MODE-OPTS["MODE-CONTIN"]
    this.comp-mode = COMP-OPTS["CMODE-TRAD"]
    this.rate = RATE-OPTS["128-HZ"]
    this.convert-ms = ((1.0 / this.rate) * 1000).ceil.to-int
    this.fsr = FSR-VOLTS["FSR-2048"]
    this.lsb = LSB-OPTS["FSR-2048"]
    this.mux = MUX-OPTS["MUX-SINGLE-0"]
    this.current-channel = 0

  constructor --pga/string --mode/string --comp-mode/string 
      --rate/string 
      --fsr/string
      --mux/string
      --current-channel/int:
    this.pga = FSR-OPTS[pga]
    this.mode = MODE-OPTS[mode]
    this.comp-mode = COMP-OPTS[comp-mode]
    this.rate = RATE-OPTS[rate]
    this.convert-ms = ((1.0 / this.rate) * 1000).ceil.to-int
    this.fsr = FSR-VOLTS[fsr]
    this.lsb = LSB-OPTS[fsr]
    this.mux = MUX-OPTS[mux]
    this.current-channel = current-channel

  config-bits -> int:
    bits := 0
        | CQUE-NONE_       // Disable comparator queue.
        | CLAT-NONLAT_     // Don't latch the comparator.
        | CPOL-ACTVLOW_    // Alert/Rdy active low.
        | this.comp-mode   // comparator mode
        | this.rate       // sample rate
        | this.mode      // Sample mode.
        // When changing this configuration, don't forget to update the toitdoc of $read.
        | this.pga       // Range +/_4.096V.
        | this.mux
        | OS-STARTCONV   // Start conversion - this initiates the inital converstion when writing to the register. Basically starts the measuring process.
    return bits

  print-config-bits -> none:
    bits := this.config-bits
    print "$(%b bits)"
  



  

class ADS:
  config/Config := Config.from-default
  registers/serial.Registers
  convert-ready-mode/bool := false


  constructor device/serial.Device:
    this.registers = device.registers
    this.registers.write-u16-be REGISTER-CONFIG this.config.config-bits
  
  set-convert-ready -> none:
    this.registers.write-u16-be REGISTER-LOWTHRESH CONVERT-READY-LO
    this.registers.write-u16-be REGISTER-HITHRESH CONVERT-READY-HI
    this.convert-ready-mode = true

  is-busy -> bool:
    config-value := this.registers.read_u16_be REGISTER-CONFIG
    return config-value & OS_MASK_ == OS_BUSY_


  read-cur-raw  -> int:
    while this.is-busy:
      sleep --ms=this.config.convert-ms
    return this.registers.read-i16-be REGISTER-CONVERT
  
  read-cur-v -> float:
    while this.is-busy:
      sleep --ms=this.config.convert-ms
    return this.read-cur-raw * this.config.lsb
  
  read-rms-v samp-count/int=60 -> float:
    run-sum := 0.0
    samp-count.repeat:
      run-sum += (math.pow this.read-cur-v 2)
    return math.sqrt (run-sum / samp-count)
    