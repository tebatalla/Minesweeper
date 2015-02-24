module Kernel

  def ap(object, options = {})
    print object.ai(options)
    object unless AwesomePrint.console?
  end

end
