CXX = srun --gres=gpu:1 -u /usr/local/cuda/bin/nvcc
TARGET = intervalJoin

all: intervalJoin.cu
	$(CXX) $< -o $(TARGET)

.PHONY: clean run

clean:
	rm -f $(TARGET) 

run:
	srun --gres=gpu:1 -u ./$(TARGET)
