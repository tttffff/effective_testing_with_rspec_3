class Coffee
  def ingredients
    @ingredients ||= []
  end

  def add(ingredient)
    ingredients << ingredient
  end

  def price
    1.00 + ingredients.size * 0.25
  end

  def colour
    ingredients.include?(:milk) ? :light : :dark
  end

  def temperature
    ingredients.include?(:milk) ? 190.0 : 205.0
  end

  def inspect
    "#<Coffee #{ingredients.join(', ')}>"
  end
end

RSpec.describe "A cup of coffee" do
  let(:coffee) { Coffee.new }

  it "costs $1" do
    expect(coffee.price).to eq(1.00)
  end

  context "with milk" do
    before { coffee.add :milk }

    it "costs $1.25" do
      expect(coffee.price).to eq(1.25)
    end

    it "is light in colour" do
      expect(coffee.colour).to be(:light)
    end

    it "is cooler than 200 degrees Fahrenheit" do
      expect(coffee.temperature).to be < 200.0
    end
  end
end
