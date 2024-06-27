from prometheus_client import start_http_server, Gauge
import pyvisa
import redis
import os

if __name__ == '__main__':
    # Load Resources
    rm = pyvisa.ResourceManager()
    print("Availible Resources: " + str(rm.list_resources()))

    # Find Power Supply, Redis
    ps_address = "USB0::62700::5168::SPD3XJFQ7R5057\x00\x00\x00\x00::0::INSTR"
    redis_address = "localhost"

    if "ps_address" in os.environ:
        ps_address = os.environ["ps_address"]
    if "redis_address" in os.environ:
        redis_address = os.environ["redis_address"]

    print("Connecting to PS: " + ps_address + ", Redis: " + redis_address)
    
    ps = rm.open_resource(ps_address)
    ps.write_termination = "\n"
    ps.read_termination = "\n"
    
    ch1_voltage = Gauge("ch1_voltage", "Output Voltage (Ch 1)")
    ch1_voltage_max = Gauge("ch1_voltage_max", "Maximum Voltage (Ch 1)")

    ch2_voltage = Gauge("ch2_voltage", "Output Voltage (Ch 2)")
    ch2_voltage_max = Gauge("ch2_voltage_max", "Maximum Voltage (Ch 2)")
    
    ch1_current = Gauge("ch1_current", "Output Current (Ch 1)")
    ch1_current_max = Gauge("ch1_current_max", "Maximum Current (Ch 1)")
    
    ch2_current = Gauge("ch2_current", "Output Current (Ch 2)")
    ch2_current_max = Gauge("ch2_current_max", "Maximum Current (Ch 2)")
    redis_client = redis.StrictRedis(redis_address, 6379, charset="utf-8", decode_responses=True)

    # Start Server
    start_http_server(5000)

    while True:
        ch1_voltage_val = ps.query("MEAS:VOLT? CH1")
        ch1_voltage.set(ch1_voltage_val)
        ch1_voltage_max.set(ps.query("CH1:VOLT?"))

        ch2_voltage_val = ps.query("MEAS:VOLT? CH2")
        ch2_voltage.set(ch2_voltage_val)
        ch2_voltage_max.set(ps.query("CH2:VOLT?"))

        ch1_current_val = ps.query("MEAS:CURR? CH1")
        ch1_current.set(ch1_current_val)
        ch1_current_max.set(ps.query("CH1:CURR?"))

        ch2_current_val = ps.query("MEAS:CURR? CH2")
        ch2_current.set(ch2_current_val)
        ch2_current_max.set(ps.query("CH2:CURR?"))

        redis_client.hset("PowerSuppliesLV", mapping={
            "PowerSupplies/PS_LabLV/V1": ch1_voltage_val,
            "PowerSupplies/PS_LabLV/V2": ch2_voltage_val,
            "PowerSupplies/PS_LabLV/I1": ch1_current_val,
            "PowerSupplies/PS_LabLV/I2": ch2_current_val
        })
