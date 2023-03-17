class Tea
  def taste = :earl_grey
  def temperature = 205.0
end

RSpec.describe Tea do
  let(:tea) { Tea.new }

  it "tastes like Earl Grey" do
    expect(tea.taste).to be :earl_grey
  end

  it "is hot" do
    expect(tea.temperature).to be > 100.0
  end
end
