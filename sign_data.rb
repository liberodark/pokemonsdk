# This script is meant to be used in future compilation process (signed data by maker)
# It's not usable as is but you can try to use it this way:
# ruby sign_data.rb some_file
require 'openssl.bundle'
unless File.exist?('certificates.dat')
  rsa_key = OpenSSL::PKey::RSA.new(2048)
  File.binwrite('certificates.dat', Marshal.dump({ private: rsa_key.to_pem, public: rsa_key.public_key.to_pem }))
end

certificates = Marshal.load(File.binread('certificates.dat'))
data = File.binread(ARGV[0])
signature = OpenSSL::PKey::RSA.new(certificates[:private]).sign(OpenSSL::Digest.new('sha256'), data)
puts certificates[:public].split("\n")[1...-1].join("\n")
puts OpenSSL::PKey::RSA.new(certificates[:public]).verify(OpenSSL::Digest.new('sha256'), signature, data)
puts signature.bytesize, signature
