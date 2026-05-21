control "ssh-hardening" do
  impact 0.7
  title "SSH endurecido"
  desc "Comprueba que SSH no permite root, limita intentos y muestra banner."

  describe sshd_config do
    its("PermitRootLogin") { should cmp "no" }
    its("MaxAuthTries") { should cmp "3" }
    its("X11Forwarding") { should cmp "no" }
    its("Banner") { should cmp "/etc/issue.net" }
  end

  describe file("/etc/ssh/sshd_config") do
    it { should exist }
    its("owner") { should eq "root" }
    its("group") { should eq "root" }
    its("mode") { should cmp "0600" }
  end

  describe port(22) do
    it { should be_listening }
    its("protocols") { should include "tcp" }
  end
end
