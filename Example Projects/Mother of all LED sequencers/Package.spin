{{
OBEX LISTING:
  http://obex.parallax.com/object/399

  This module is a modified copy of my module "Mother of all LED Sequencers"
  In simple terms this software takes bit patterns from memory and passes them to the I/O ports.
  It will work with the Propeller demo Board, The Quickstart board and the PropBOE board.
  It also works with an led driver based on a 74HC595 shift register of my own design
  (See MyLed object for details).The differences between this and the original OBEX module is that
  first this is all spin, second this uses a circular list, and third this is modified to be able
  to wait for an input rather than being strictly timed sequences.

}}
{{                       Move along
          ====== There is nothing to see here! ======
          Im only using this to make sure the Archive
            contains all the versions and modules.

}}

OBJ
  A: "LEDSequencer_asm"        ' The original
  D: "DisplaySequencer"        ' V2 in Spin

Pub Package
