# PostfixDaemon

Postfixのデーモンプログラムを作るためのライブラリです。

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'postfix_daemon'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install postfix_daemon

## Usage

プログラムを書きます。

入力を大文字に変換して返すプログラムの例:

```ruby
#!/path/to/ruby

require 'postfix_daemon'

# エラー終了してもどこにも出力されないのでリダイレクトしといた方がよさそう
$stderr.reopen("/tmp/error.log", "a+")

PostfixDaemon.start do |socket, addr|
  socket.puts "you are #{addr.inspect}"
  while s = socket.gets
    s = s.force_encoding("utf-8").scrub
    socket.puts s.upcase
  end
end
```

プログラムを /usr/lib/postfix/sbin に置きます。

```
# cp hoge.rb /usr/lib/postfix/sbin/hoge
# chmod +x /usr/lib/postfix/sbin/hoge
```

master.cf に追加:

```
12345   inet   -   -   -   -   -   hoge
```

postfix reload

```
# postfix reload
```

```
% nc localhost 12345
you are #<Addrinfo: 127.0.0.1:59312 TCP>
abcdefg
ABCDEFG
^C
```
