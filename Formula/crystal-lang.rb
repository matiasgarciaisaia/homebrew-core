class CrystalLang < Formula
  desc "Fast and statically typed, compiled language with Ruby-like syntax"
  homepage "https://crystal-lang.org/"

  stable do
    url "https://github.com/crystal-lang/crystal/archive/0.25.1.tar.gz"
    sha256 "9b5a7bd2de67ab36cc5430133228a1e656a431fc7d928a37a61109bd8da77fc6"

    resource "shards" do
      url "https://github.com/crystal-lang/shards/archive/v0.8.1.tar.gz"
      sha256 "75c74ab6acf2d5c59f61a7efd3bbc3c4b1d65217f910340cb818ebf5233207a5"
    end
  end

  bottle do
    sha256 "5331928212087fad6434ec46031d1d5a7bbca583943e726ae2a1e119637b4337" => :high_sierra
    sha256 "28f29b34da9ab7b9d47873fe72cb910879aa68b14f3a2cedd95d22d98d63ad92" => :sierra
    sha256 "26b09b77b78d71a6d4b74cf28cb1890976124fe4f315dc6f3522f28b6d1b252b" => :el_capitan
  end

  head do
    url "https://github.com/crystal-lang/crystal.git"

    resource "shards" do
      url "https://github.com/crystal-lang/shards.git"
    end
  end

  option "without-release", "Do not build the compiler in release mode"
  option "without-shards", "Do not include `shards` dependency manager"

  depends_on "pkg-config" => :build
  depends_on "libatomic_ops" => :build # for building bdw-gc
  depends_on "libevent"
  depends_on "bdw-gc"
  depends_on "llvm@5"
  depends_on "pcre"
  depends_on "gmp" # std uses it but it's not linked
  depends_on "libyaml" if build.with? "shards"

  resource "boot" do
    if MacOS.version <= :el_capitan # no clock_gettime
      url "https://github.com/crystal-lang/crystal/releases/download/v0.24.1/crystal-0.24.1-2-darwin-x86_64.tar.gz"
      version "0.24.1"
      sha256 "2be256462f4388cd3bb14b1378ef94d668ab9d870944454e828b4145155428a0"
    else
      url "https://github.com/crystal-lang/crystal/releases/download/0.25.0/crystal-0.25.0-1-darwin-x86_64.tar.gz"
      version "0.25.0"
      sha256 "3e1ec645a2fd86917e9af86fe9352812ae3e6bd17622ac69b9b311948a14ce00"
    end
  end

  def install
    (buildpath/"boot").install resource("boot")

    if build.head?
      ENV["CRYSTAL_CONFIG_VERSION"] = Utils.popen_read("git rev-parse --short HEAD").strip
    else
      ENV["CRYSTAL_CONFIG_VERSION"] = version
    end

    ENV["CRYSTAL_CONFIG_PATH"] = prefix/"src:lib"
    ENV.append_path "PATH", "boot/bin"

    system "make", "deps"
    (buildpath/".build").mkpath

    command = ["bin/crystal", "build", "-D", "without_openssl", "-D", "without_zlib", "-o", ".build/crystal", "src/compiler/crystal.cr"]
    command.concat ["--release", "--no-debug"] if build.with? "release"

    system *command

    if build.with? "shards"
      resource("shards").stage do
        system buildpath/"bin/crystal", "build", "-o", buildpath/".build/shards", "src/shards.cr"
      end
      bin.install ".build/shards"
    end

    bin.install ".build/crystal"
    prefix.install "src"
    bash_completion.install "etc/completion.bash" => "crystal"
    zsh_completion.install "etc/completion.zsh" => "_crystal"
  end

  test do
    assert_match "1", shell_output("#{bin}/crystal eval puts 1")
  end
end
