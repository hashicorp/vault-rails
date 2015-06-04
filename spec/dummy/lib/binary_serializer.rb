# Encodes and decodes binary data.
module BinarySerializer
  def self.encode(raw)
    raw.unpack("B*")[0]
  end

  def self.decode(raw)
    [raw].pack("B*")
  end
end
