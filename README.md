# Running on host

MIX_TARGET=host mix deps.get
MIX_TARGET=host iex -S mix scenic.run

# Running on RPI3

MIX_TARGET=adsb_nerves_rpi3 mix deps.get
MIX_TARGET=adsb_nerves_rpi3 mix firmware.burn
