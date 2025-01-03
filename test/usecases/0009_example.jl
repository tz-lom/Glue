module TestCase0009

using ..Utils
using FunctionFusion


# Let's solve the example problem
# Two one-dimensional trains are departing from different stations located at specified points in specified directions
# Model shall return distance between trains after given amount of time
# Depending on the region coordinates and speeds may be specified in different units, that shall be taken in account for the implementation.
# The algorithm will be deployed in two regions:
# 1 - generic countries and accept meters as distance and meters per second as speeds
# 2 - scientific cgs platform where distance is in centimiters



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

# @template new_location normalize_speed normalize_start compute_new_location
@algorithm new_location[normalize_speed, normalize_start, compute_new_location](
    C_Speed,
    C_Start,
)::C_End implement = false

# We would need to apply this algorithm for train A anb B, let's define intermediate artifacts and applications

@artifact TrainANewLocation, TrainBNewLocation = Float64

# @implement new_location_A new_location TrainALocation => C_Start TrainASpeed => C_Speed Time =>
# C_Time C_End => TrainANewLocation

@use new_location_A = new_location{
    C_Start => TrainALocation,
    C_Speed => TrainASpeed,
    C_Time => Time,
    C_End => TrainANewLocation,
}

@use new_location_B = new_location{
    C_Start => TrainBLocation,
    C_Speed => TrainBSpeed,
    C_Time => Time,
    C_End => TrainBNewLocation,
}


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

# metric platform 

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

function expected_in_metric(
    a_location::Float64,
    a_speed::Float64,
    b_location::Float64,
    b_speed::Float64,
    time::Float64,
)::Float64
    return -(a_location + a_speed * time) + (b_location + b_speed * time)
end

verifyEquals(compute_in_metric, expected_in_metric, 1.0, 1.0, 5.0, 2.0, 3.0)
verifyVisualization(compute_in_metric, "0009_metric")

# cgs platform

@provider function normalize_speed_cgs(s::C_Speed)::C_Speed_Normalized
    s * 0.01
end
@provider function normalize_start_cgs(s::C_Start)::C_Start_Normalized
    s * 0.01
end

@algorithm compute_in_cgs[
    full_algorithm,
    substitute(normalize_speed, normalize_speed_cgs),
    substitute(normalize_start, normalize_start_cgs),
](
    TrainALocation,
    TrainASpeed,
    TrainBLocation,
    TrainBSpeed,
    Time,
)::FinalDistance

function expected_in_cgs(
    a_location::Float64,
    a_speed::Float64,
    b_location::Float64,
    b_speed::Float64,
    time::Float64,
)::Float64
    return - (a_location * 0.01 + a_speed * 0.01 * time) +  (b_location * 0.01 + b_speed * 0.01 * time)
end

verifyEquals(compute_in_cgs, expected_in_cgs, 1.0, 1.0, 5.0, 2.0, 3.0)
verifyVisualization(compute_in_cgs, "0009_cgs")



end