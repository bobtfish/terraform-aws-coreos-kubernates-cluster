.PHONEY: all

all: variables.tf.json
	true

clean:
	rm -f variables.tf.json

variables.tf.json:
	ruby getvariables.rb > variables.tf.json

