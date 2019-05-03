require 'osc-ruby'

module Xi
  module OSC
    def initialize(name, clock, server: 'localhost', port:, **opts)
      super
      @osc = ::OSC::Client.new(server, port)
    end

    private

    def send_msg(address, *args)
      msg = message(address, *args)
      debug(__method__, msg.address, *msg.to_a)
      send_osc_msg(msg)
    end

    def send_bundle(address, *args, at: Time.now)
      msg = message(address, *args)
      bundle = ::OSC::Bundle.new(at, msg)
      debug(__method__, msg.address, at.to_i, at.usec, *msg.to_a)
      send_osc_msg(bundle)
    end

    def message(address, *args)
      ::OSC::Message.new(address, *args)
    end

    def send_osc_msg(msg)
      @osc.send(msg)
    rescue StandardError => err
      error(err)
    end
  end
end
