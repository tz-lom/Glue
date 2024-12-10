module TestCase0009

using ..Utils
using FunctionFusion


# Let's solve the example problem
# Two one-dimensional trains are departing from different stations located at specified points in specified directions
# Model shall return distance between trains after given amount of time
# Depending on the region coordinates and speeds may be specified in different units, that shall be taken in account for the implementation.
# The algorithm will be deployed in two regions:
# 1 - generic countries and accept meters as distance and meters per second as speeds
# 2 - Antarctica penguins, penguins measure distance in penguins ( 0.42 meter) and speed in fish-fly-distance



# Define inputs of the model

@artifact TrainASpeed, TrainALocation = Float64
@artifact TrainBSpeed, TrainBLocation = Float64
@artifact Time = Float64

# define output of the model
@artifact FinalDistance = Float64



# as we need similar algorithm computing new position for both trains let's describe it as Composed

# inputs and outputs
@artifact C_Start, C_Speed, C_Time, C_End = Float64

# As we would need to normalize units let's introduce the procedure

@artifact C_Start_Normalized, C_Speed_Normalized = Float64

@unimplemented normalize_speed(C_Speed)::C_Speed_Normalized
@unimplemented normalize_start(C_Start)::C_Start_Normalized

@provider function compute_new_location(
    start::C_Start_Normalized,
    speed::C_Speed_Normalized,
    time::C_Time,
)::C_End
    return start + speed * time
end

@template new_location normalize_speed normalize_start compute_new_location

# We would need to apply this algorithm for train A anb B, let's define intermediate artifacts and applications

@artifact TrainANewLocation, TrainBNewLocation = Float64

@implement new_location_A new_location TrainALocation => C_Start TrainASpeed => C_Speed Time =>
    C_Time C_End => TrainANewLocation

@implement(
    new_location_B,
    new_location,
    TrainBLocation => C_Start,
    TrainBSpeed => C_Speed,
    Time => C_Time,
    C_End => TrainBNewLocation,
)
const train_positions = [new_location_A, new_location_B]

# algorithm to compute the result

@provider function compute_final_distance(
    a::TrainANewLocation,
    b::TrainBNewLocation,
)::FinalDistance
    return b - a
end

const full_algorithm = [train_positions, compute_final_distance]


# Now we deploy this algorithms to platforms

@provider function normalize_speed_metric(s::C_Speed)::C_Speed_Normalized
    s
end
@provider function normalize_start_metric(s::C_Start)::C_Start_Normalized
    s
end

@algorithm compute_in_metric[
    full_algorithm,
    substitute(normalize_speed, normalize_speed_metric),
    substitute(normalize_start, normalize_start_metric),
](
    TrainALocation,
    TrainASpeed,
    TrainBLocation,
    TrainBSpeed,
    Time,
)::FinalDistance

# verifyEquals(generated, expected, 1)

# verifyVisualization(generated, "0005")


end