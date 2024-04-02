STDIN.close
Object.send(:remove_const, :STDIN)
$stdin = nil
