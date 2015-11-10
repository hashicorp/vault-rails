# Encodes and decodes binary data.
module BinarySerializer
  def self.encode(raw)
    return raw if raw.blank?
    raw.unpack("B*")[0]
  end

  def self.decode(raw)
    return raw if raw.blank?
    [raw].pack("B*")
  end
end
