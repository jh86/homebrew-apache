require "formula"

class ModPython < Formula
  class CLTRequirement < Requirement
    fatal true
    satisfy { MacOS.version < :mavericks || MacOS::CLT.installed? }

    def message; <<-EOS.undent
      Command Line Tools required, even if Xcode is installed, on OS X 10.9 or
      10.10 and not using Homebrew httpd22 or httpd24. Resolve by running
        xcode-select --install
      EOS
    end
  end

  homepage "http://modpython.org/"
  url "http://dist.modpython.org/dist/mod_python-3.5.0.tgz"
  sha1 "9208bb813172ab51d601d78e439ea552f676d2d1"
  sha256 "0ef09058ed98b41c18d899d8b710a0cce2df2b53c44d877401133b3f28bdca90"

  option "with-homebrew-httpd22", "Use Homebrew Apache httpd 2.2"
  option "with-homebrew-httpd24", "Use Homebrew Apache httpd 2.4"
  option "with-homebrew-python", "Use Homebrew python"

  depends_on "httpd22" if build.with? "homebrew-httpd22"
  depends_on "httpd24" if build.with? "homebrew-httpd24"
  depends_on "python" if build.with? "homebrew-python"
  depends_on CLTRequirement if build.without? "homebrew-httpd22" and build.without? "homebrew-httpd24"

  if build.with? "homebrew-httpd22" and build.with? "homebrew-httpd24"
    onoe "Cannot build for http22 and httpd24 at the same time"
    exit 1
  end

  def apache_apxs
    if build.with? "homebrew-httpd22"
      %W[sbin bin].each do |dir|
        if File.exist?(location = "#{Formula['httpd22'].opt_prefix}/#{dir}/apxs")
          return location
        end
      end
    elsif build.with? "homebrew-httpd24"
      %W[sbin bin].each do |dir|
        if File.exist?(location = "#{Formula['httpd24'].opt_prefix}/#{dir}/apxs")
          return location
        end
      end
    else
      "/usr/sbin/apxs"
    end
  end

  def apache_configdir
    if build.with? "homebrew-httpd22"
      "#{etc}/apache2/2.2"
    elsif build.with? "homebrew-httpd24"
      "#{etc}/apache2/2.4"
    else
      "/etc/apache2"
    end
  end

  def install
    args = "--prefix=#{prefix}"
    args << "--with-apxs=#{apache_apxs}"
    args << "--with-python=#{HOMEBREW_PREFIX}/bin/python" if build.with? "homebrew-python"
    system "./configure", *args

    system "make"

    libexec.install "src/.libs/mod_python.so"
  end

  def caveats; <<-EOS.undent
    You must manually edit #{apache_configdir}/httpd.conf to include
      LoadModule python_module #{libexec}/mod_python.so

    NOTE: If you're _NOT_ using --with-homebrew-httpd22 or --with-homebrew-httpd24 and having
    installation problems relating to a missing `cc` compiler and `OSX#{MacOS.version}.xctoolchain`,
    read the "Troubleshooting" section of https://github.com/Homebrew/homebrew-apache
    EOS
  end

end
