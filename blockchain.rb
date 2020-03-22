require 'digest'
require 'pp'
require 'colorize'

class Block
  attr_reader :payload
  attr_reader :prev_hash
  attr_reader :hash
  attr_reader :nonce

  FIRST_BLOCK_INDEX = 0
  FIRST_BLOCK_PREVIOUS_HASH = 0

  def initialize(index, data, prevoius_hash)
    @payload = { index: index,
                 timestamp: Time.now,
                 data: data }
    @prevoius_hash = prevoius_hash
    @nonce = create_proof_of_work
    @hash = create_payload_hash
  end

  def difficulty
    d = rand(1000)
    puts "Difficulty #{d} has been picked for this block.".blue
    d.to_s
  end

  def create_proof_of_work()
    puts "\nProccessing block's proof of work ...".blue
    problem = difficulty
    nonce = 0
    loop do
      sha = Digest::SHA256.new
      sha.update(nonce.to_s + @payload.to_s + @prevoius_hash.to_s)
      if ENV["DEBUG"] == 'true'
        puts "nonce #{nonce} => #{sha.hexdigest}".yellow
      else
        print ".".white
      end
      if sha.hexdigest.start_with?(problem)
        puts "\nSolved: #{sha.hexdigest}\n".red
        return nonce
      end
      nonce += 1
    end
  end

  def create_payload_hash
    puts "Hashing the block payload ...".green
    sha = Digest::SHA256.new
    sha << @nonce.to_s + @payload.to_s + @prevoius_hash.to_s
  end

  def self.first(data)
    Block.new(FIRST_BLOCK_INDEX, data, FIRST_BLOCK_PREVIOUS_HASH)
  end

  def self.next(prev_block, data)
    Block.new((prev_block.payload[:index].to_i + 1), data, prev_block.hash)
  end
end

class Blockchain
  attr_reader :chain

  def initialize()
    @chain = []
  end

  def add(block)
    @chain.empty? ? (@chain << block) : (@chain << trusted?(@chain.last, block))
  end

  def trusted?(prev_block, next_block)
    state = ((prev_block.payload[:index] + 1).eql? next_block.payload[:index] and
            Digest::SHA256.hexdigest(next_block.nonce.to_s + next_block.payload.to_s + prev_block.hash.to_s) == next_block.hash.to_s)
    if state
      return next_block
    else
      abort "Error: Blockchain is not trusted:
      previous block hash: #{prev_block.hash}
      Next block hash: #{next_block.hash}".red
    end
  end
end

# RUN:
b0 = Block.first("Initial block")
b1 = Block.next(b0, "Blockchain transaction 1")
b2 = Block.next(b1, "Blockchain transaction 2")
b3 = Block.next(b2, "Blockchain transaction 3")
b4 = Block.next(b3, "Blockchain transaction 4")
b5 = Block.next(b4, "Blockchain transaction 5")

blockchain = Blockchain.new
blockchain.add(b0)
blockchain.add(b1)
blockchain.add(b2)
blockchain.add(b3)
blockchain.add(b4)
blockchain.add(b5)
pp blockchain
