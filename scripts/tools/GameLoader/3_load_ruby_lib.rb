require 'zlib.so'
require 'openssl.so'

Marshal.load(Zlib::Inflate.inflate(File.binread(File.join(PSDK_LIB_PATH, 'ruby-lib')))).each do |b|
  RubyVM::InstructionSequence.load_from_binary(b).eval
end
