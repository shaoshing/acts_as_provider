
require 'lib/acts_as_provider.rb'

describe "ActsAsProvider" do
  
  before(:each) do
    class Author
      def name    ; "sxlee" ; end
      def address ; "hzu"   ; end
    end
    class Book
      include ActsAsProvider
      def title   ; "Rails" ; end
      def content ; "Good!"   ; end
      def author
        @author ||= Author.new
      end
    end
  end
  
  describe "[ClassMethods]:" do
    describe "[acts_as_provider]" do
      
      it "调用提供的block代码" do
        class Book
          called = false
          acts_as_provider do |o|
            called = true
          end
          called.should == true
        end
      end
      
      it "调用时提供 provider实例变量" do
        class Book
          acts_as_provider do |o|
            o.is_a?(ActsAsProvider::Provider).should == true
          end
        end
      end
      
    end
  end
  
  describe "[Provider]" do
    
    before(:each) do ; @bp = ActsAsProvider::Provider.new ; end
    
    it "记录要 provide 的内容" do
      @bp.describe do
        add.self
        add.order_item
        add.order_item.pattern
      end   
      @bp.sources[0].should == { :matcher => /^/                   , :append_str => "" }
      @bp.sources[1].should == { :matcher => /^order_item_/        , :append_str => "order_item." }
      @bp.sources[2].should == { :matcher => /^order_item_pattern_/, :append_str => "order_item.pattern." }
    end
  
    describe "方法 [provide(target, fields)]" do
      
      it "如果target响应相应的field，则调用target的方法" do
        book = Object.new
        book.should_receive(:respond_to?).twice.and_return true
        book.should_receive(:a).and_return 1
        book.should_receive(:b).and_return 2
        @bp.describe do
          add.self
        end
        @bp.provide( book, ["a", "b"] )
      end
      
      it "如果仅设置了子域，则会调用子域本身的方法来组成数据" do
        book = Object.new
        author = Object.new
        book.stub!(:author).and_return author
        author.should_receive(:name).and_return "sxlee"
        author.should_receive(:address).and_return "hzu"
        @bp.describe do |bp|
          add.author
        end
        @bp.provide( book, ["author_name", "author_address"] )
      end
    end
  end
  
  describe "[InstanceMethods]" do
    
    before(:each) do
      class Book
        acts_as_provider do
          add.self
          add.author
        end
      end
      @book = Book.new
    end
    
    describe "实例方法[provide]:" do
      
      it "返回空数据" do
        @book.provide(nil).should == {}
        @book.provide([]).should == {}
      end
      
      it "正确返回本身方法的数据" do
        @book.provide(["title"]).should == { "title" => "Rails" }
        @book.provide(["title","content"]).should == { "title" => "Rails", "content" => "Good!"  }
      end
      
      it "正确返回子域方法的数据" do
        @book.provide(["author_name"]).should == { "author_name" => "sxlee" }
        @book.provide(["author_name","author_address"]).should == { 
          "author_name" => "sxlee", "author_address" => "hzu"  }
      end
      
      it "正确返回全部方法" do
        @book.provide(["title", "content", "author_name","author_address"]).should == { 
          "title"           => "Rails",
          "content"         => "Good!",
          "author_name"     => "sxlee", 
          "author_address"  => "hzu"  
        }
      end
      
      describe "Error" do
        
        it "当重复调用 acts_as_provider 时抛出异常" do
          # lambda{
          #   class Book
          #     acts_as_provider do ; add.no_method ; end
          #     acts_as_provider do ; add.duplicate ; end
          #   end
          # }.should raise_error(ActsAsProvider::Error)
        end
        
        it "当无法映射时抛出异常" do
          lambda{
            @book.provide(["invalid_field"])
          }.should raise_error(ActsAsProvider::Error)
        end
        
        it "当因 no methods 无法映射时抛出异常" do
          lambda{
            class Book
              acts_as_provider do ; add.no_method ; end
            end
            Book.new.provide(["no_method_field"])
          }.should raise_error(ActsAsProvider::Error)
        end
        
      end
      
    end
  end
  
  describe "复杂测试" do
    it do
      class ClothPart
        include ActsAsProvider
        acts_as_provider do
          add.self
          add.product
          add.type
          add.product.variety
          add.product.yarn_standard
          add.order_item.order
          add.manufacture_task
        end
      end
      cloth_part       = ClothPart.new
      product          = Object.new
      type             = Object.new
      variety          = Object.new
      yarn_standard    = Object.new
      manufacture_task = Object.new
      order_item       = Object.new
      order            = Object.new

      cloth_part.stub!(:product).and_return product
      cloth_part.stub!(:type).and_return type
      cloth_part.stub!(:manufacture_task).and_return manufacture_task
      cloth_part.stub!(:order_item).and_return order_item
      product.stub!(:variety).and_return variety
      product.stub!(:yarn_standard).and_return yarn_standard
      order_item.stub!(:order).and_return order
      
      cloth_part.should_receive :id
      cloth_part.should_receive :remark
      product.should_receive :number
      type.should_receive :name
      variety.should_receive :number
      yarn_standard.should_receive :number
      manufacture_task.should_receive :man_type
      manufacture_task.should_receive :quantity
      order.should_receive :delivery_date
      
      cloth_part.provide([ 
        'id', 
        'product_number', 
        'type_name',
        'product_variety_number',
        'product_yarn_standard_number',
        'manufacture_task_man_type', 
        'manufacture_task_quantity',
        'order_item_order_delivery_date',
        'remark'
      ])
      
    end
  end
  
end
