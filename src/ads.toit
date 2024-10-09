import binary
import serial.device as serial
import serial.registers as serial

DEFAULT_I2C_ADDRESS ::= 0x48
ALT_I2C_ADDRESS::= 0x49

REGISTER_MASK_ ::= 0x03
REGISTER_CONVERT_ ::= 0x00
REGISTER_CONFIG ::= 0x01
REGISTER_LOWTHRESH_ ::= 0x02
REGISTER_HITHRESH_ ::= 0x03

OS_MASK_ ::= 0x8000
OS_SINGLE_ ::= 0x8000  // Write: Set to start a single-conversion.
OS_BUSY_ ::= 0x0000    // Read: Bit=0 when conversion is in progress.
OS_NOTBUSY_ ::= 0x8000 // Read: Bit=1 when no conversion is in progress.

MUX_MASK_ ::= 0x7000
MUX_OPTS ::={
  "MUX_DIFF_0_1" : 0x0000,  // Differential P  =  AIN0, N  =  AIN1 (default).
  "MUX_DIFF_0_3" : 0x1000,  // Differential P  =  AIN0, N  =  AIN3.
  "MUX_DIFF_1_3" : 0x2000,  // Differential P  =  AIN1, N  =  AIN3.
  "MUX_DIFF_2_3" : 0x3000,  // Differential P  =  AIN2, N  =  AIN3.
  "MUX_SINGLE_0" : 0x4000,  // Single-ended AIN0.
  "MUX_SINGLE_1" : 0x5000,  // Single-ended AIN1.
  "MUX_SINGLE_2" : 0x6000,  // Single-ended AIN2.
  "MUX_SINGLE_3" : 0x7000,  // Single-ended AIN3.
}


SINGLE_ENDED_ ::= [MUX_SINGLE_0_, MUX_SINGLE_1_, MUX_SINGLE_2_, MUX_SINGLE_3_]

CPOL_MASK_ ::= 0x0008
CPOL_ACTVLOW_ ::= 0x0000  // ALERT/RDY pin is low when active (default).
CPOL_ACTVHI_ ::= 0x0008  // ALERT/RDY pin is high when active.

CLAT_MASK_ ::= 0x0004  // Determines if ALERT/RDY pin latches once asserted.
CLAT_NONLAT_ ::= 0x0000  // Non-latching comparator (default).
CLAT_LATCH_ ::= 0x0004  // Latching comparator.

CQUE_MASK_ ::= 0x0003
CQUE_1CONV_ ::= 0x0000  // Assert ALERT/RDY after one conversions.
CQUE_2CONV_ ::= 0x0001  // Assert ALERT/RDY after two conversions.
CQUE_4CONV_ ::= 0x0002  // Assert ALERT/RDY after four conversions.
// Disable the comparator and put ALERT/RDY in high state (default).
CQUE_NONE_ ::= 0x0003


FSR_MASK ::=   0x0E00
FSR_OPTS := {
  "FSR_6144" : 0x0000,  // +/-6.144V range  =  Gain 2/3.
  "FSR_4096" : 0x0200,  // +/-4.096V range  =  Gain 1.
  "FSR_2048" : 0x0400,  // +/-2.048V range  =  Gain 2 (default).
  "FSR_1024" : 0x0600,  // +/-1.024V range  =  Gain 4.
  "FSR_0512" : 0x0800,  // +/-0.512V range  =  Gain 8.
  "FSR_0256" : 0x0A00,  // +/-0.256V range  =  Gain 16.
}

FSR_VOLTS ::={
  "FSR_6144" : 6.144,
  "FSR_4096" : 4.096,
  "FSR_2048" : 2.048,
  "FSR_1024" : 1.024,
  "FSR_0512" : 0.512,
  "FSR_0256" : 0.256,
}


MODE_MASK_ ::=   0x0100
MODE_OPTS :={
  "MODE_CONTIN" : 0x0000,  // Continuous conversion mode.
  "MODE_SINGLE" : 0x0100,  // Power-down single-shot mode (default).
}


CMODE_MASK_ ::= 0x0010
COMP_OPTS ::={
  "CMODE_TRAD" : 0x0000,  // Traditional comparator with hysteresis (default).
  "CMODE_WINDOW" : 0x0010,  // Window comparator.
}

RATE_OPTS ::={
  "008_HZ" : 0x0000, // 8 samples per second.
  "016_HZ" : 0x0020, // 16 samples per second.
  "032_HZ" : 0x0040, // 32 samples per second.
  "064_HZ" : 0x0060, // 64 samples per second.
  "128_HZ" : 0x0080, // 128 samples per second (default).
  "250_HZ" : 0x00A0, // 250 samples per second.
  "475_HZ" : 0x00C0, // 475 samples per second.
  "860_HZ" : 0x00E0, // 860 samples per Second.
}




LSB_V_FSR_6114 ::= 0.0001875
LSB_V_FSR_4096 ::= 0.000125 
LSB_V_FSR_2048 ::= 0.0000625
LSB_V_FSR_1024 ::= 0.00003125
LSB_V_FSR_0512 ::= 0.000015625
LSB_V_FSR_0256 ::= 0.000007815

CHANNELS_MUX_SINGLE_0_ ::= [0, 0]
CHANNELS_MUX_SINGLE_1_ ::= [1, 0]
CHANNELS_MUX_SINGLE_2_ ::= [2, 0]
CHANNELS_MUX_SINGLE_3_ ::= [3, 0]
CHANNELS_MUX_DIFF_0_1_ ::= [0, 1]
CHANNELS_MUX_DIFF_0_3_ ::= [0, 3]
CHANNELS_MUX_DIFF_1_3_ ::= [1, 3]
CHANNELS_MUX_DIFF_2_3_ ::= [2, 3]


class Config:
  pga/int
  mode/int
  comp_mode/int
  rate/int
  fsr/float
  mux/int
  

  constructor.from_default :
    this.pga = FSR_OPTS["FSR_2048"]
    this.mode = MODE_OPTS["MODE_CONTIN"]
    this.comp_mode = COMP_OPTS["CMODE_TRAD"]
    this.rate = RATE_OPTS["128_HZ"]
    this.fsr = FSR_VOLTS["FSR_2048"]
    this.mux = MUX_OPTS["MUX_SINGLE_0"]

  constructor --pga/string --mode/string --comp_mode/string 
      --rate/string 
      --fsr/string 
      --mux/string:
    this.pga = FSR_OPTS[pga]
    this.mode = MODE_OPTS[mode]
    this.comp_mode = COMP_OPTS[comp_mode]
    this.rate = RATE_OPTS[rate]
    this.fsr = FSR_VOLTS[fsr]
    this.mux = MUX_OPTS[mux]

  config_bits -> int:
    bits := 0
        | CQUE_NONE_        // Disable comparator queue.
        | CLAT_NONLAT_      // Don't latch the comparator.
        | CPOL_ACTVLOW_     // Alert/Rdy active low.
        | this.comp_mode       // Traditional comparator.
        | this.rate       // 475 samples per second.
        | this.mode      // Single-shot mode.
        // When changing this configuration, don't forget to update the toitdoc of $read.
        | this.pga       // Range +/- 4.096V.
        | this.mux
        | OS_SINGLE_        // Begin a single conversion.
    return bits

  print_config_bits -> none:
    bits := this.config-bits
    print "$(%b bits)"

  

class ADS:
  config/Config := Config.from_default
  registers/serial.Registers

  constructor device/serial.Device:
    this.registers = device.registers
    this.registers.write_u16_be REGISTER_CONFIG this.config.config_bits
  

