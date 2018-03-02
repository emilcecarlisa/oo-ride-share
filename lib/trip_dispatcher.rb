require 'csv'
require 'time'

require_relative 'driver'
require_relative 'passenger'
require_relative 'trip'

module RideShare
  class TripDispatcher
    attr_reader :drivers, :passengers, :trips

    def initialize
      @drivers = load_drivers
      @passengers = load_passengers
      @trips = load_trips
    end

    def load_drivers
      my_file = CSV.open('support/drivers.csv', headers: true)

      all_drivers = []
      my_file.each do |line|
        input_data = {} # turn each line to a hash. if this wasn't here, we could grab the data as if they're key value pairs

        vin = line[2].length == 17 ? line[2] : "0" * 17 # checking for 17 num vin and puts zero if missing

        # Status logic
        status = line[3]
        status = status.to_sym
        # this key name now equals the data at this location
        input_data[:vin] = vin
        input_data[:id] = line[0].to_i
        input_data[:name] = line[1]
        input_data[:status] = status
        all_drivers << Driver.new(input_data)
      end

      return all_drivers
    end

    def find_driver(id)
      check_id(id) # running check id method to ensure that no blanks or negatives accepted
      @drivers.find{ |driver| driver.id == id } # calls instance var which holds load driver method
    end

    def load_passengers
      passengers = []

      CSV.read('support/passengers.csv', headers: true).each do |line|
        input_data = {}
        input_data[:id] = line[0].to_i
        input_data[:name] = line[1]
        input_data[:phone] = line[2]

        passengers << Passenger.new(input_data)
      end

      return passengers
    end

    def find_passenger(id)
      check_id(id)
      @passengers.find{ |passenger| passenger.id == id }
    end

    def load_trips
      trips = []
      trip_data = CSV.open('support/trips.csv', 'r', headers: true, header_converters: :symbol)

      trip_data.each do |raw_trip|
        driver = find_driver(raw_trip[:driver_id].to_i) # getting driver id from array, and putting in method called find driver
        # find_driver method searches the driver csv for matching driver
        passenger = find_passenger(raw_trip[:passenger_id].to_i)


        parsed_trip = {
          id: raw_trip[:id].to_i,
          driver: driver, # driver symbol is set to the driver variable defined above,
          # which is calling find_driver method through an instance variable (containing method load drivers)
          passenger: passenger,
          start_time: Time.parse(raw_trip[:start_time]),
          end_time: Time.parse(raw_trip[:end_time]),
          cost: raw_trip[:cost].to_f,
          rating: raw_trip[:rating].to_i
        }

        trip = Trip.new(parsed_trip)

        # Set up the relations
        driver.add_trip(trip)
        passenger.add_trip(trip)
        trips << trip
      end

      return trips
    end

    def request_trip()
      # helper method for in_progress
      trip_id = (trips.last.id) + 1
      available_driver = @drivers.find {|driver| driver.status == :AVAILABLE}
      start_time =  Time.now
      # if driver is available then return their id # && make them UNAVAILABLE

      data = {
        id: trip_id,
        driver: available_driver,
        passenger: find_passenger(3),
        start_time: start_time,
        end_time: nil,
        cost: nil,
        rating: nil, # OK TO BE NILL?
        }

        trip = Trip.new(data) # New instance of trip created, shoveled to trips csv or parsed array?
        driver.add_trip(trip)
        passenger.add_trip(trip)
        trips.trips << trip # attempt to shovel new trip to trips array in load_trips method

        return data # nilclass being returned for the trip rating
      end

      def inspect
        "#<#{self.class.name}:0x#{self.object_id.to_s(16)}>"
      end

      private # limited functionality, like a helper method, not to be used in other classes

      def check_id(id)
        if id == nil || id <= 0
          raise ArgumentError.new("ID cannot be blank or less than zero. (got #{id})")
        end
      end
    end
  end
