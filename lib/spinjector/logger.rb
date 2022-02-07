class Logger
  def log(content)
    raise "Abstract class, should be overriden"
  end
end

class EmptyLogger < Logger
  def log(content)
  end
end

class VerboseLogger < Logger
  def log(content)
    puts content
  end
end