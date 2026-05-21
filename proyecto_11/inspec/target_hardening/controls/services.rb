control "services-lab" do
  impact 0.5
  title "Servicios necesarios del laboratorio"
  desc "Valida HTTP y DNS como servicios controlados para la emulacion."

  describe package("nginx") do
    it { should be_installed }
  end

  describe package("dnsmasq") do
    it { should be_installed }
  end

  describe port(80) do
    it { should be_listening }
    its("protocols") { should include "tcp" }
  end

  describe port(53) do
    it { should be_listening }
    its("protocols") { should include "udp" }
  end

  describe file("/var/www/html/index.html") do
    it { should exist }
    its("content") { should match /Proyecto 11/ }
  end
end
