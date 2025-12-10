/*
 * uiBuilder C++ Backend Processor
 * 
 * Demonstrates high-performance backend integration:
 * - Receives data from PowerShell UI
 * - Performs fast computations
 * - Returns JSON results
 * 
 * Compile with:
 *   g++ -o processor processor.cpp -std=c++17
 * 
 * Usage from PowerShell:
 *   $output = & .\processor.exe --input data --operation calculate
 */

#include <iostream>
#include <string>
#include <vector>
#include <algorithm>
#include <chrono>
#include <iomanip>
#include <sstream>
#include <cmath>

// Simple JSON-like output (no external library required)
class JsonOutput {
private:
    std::stringstream ss;
    
public:
    JsonOutput& startObject() {
        ss << "{\n";
        return *this;
    }
    
    JsonOutput& endObject() {
        ss << "}";
        return *this;
    }
    
    JsonOutput& addString(const std::string& key, const std::string& value) {
        ss << "  \"" << key << "\": \"" << value << "\",\n";
        return *this;
    }
    
    JsonOutput& addNumber(const std::string& key, double value) {
        ss << "  \"" << key << "\": " << std::fixed << std::setprecision(2) << value << ",\n";
        return *this;
    }
    
    JsonOutput& addBool(const std::string& key, bool value) {
        ss << "  \"" << key << "\": " << (value ? "true" : "false") << ",\n";
        return *this;
    }
    
    std::string toString() {
        std::string result = ss.str();
        // Remove trailing comma and newline before closing brace
        if (result.back() == '\n') result.pop_back();
        if (result.back() == ',') result.pop_back();
        result += "\n}";
        return result;
    }
};

// Performance-critical calculations
class PerformanceCalculator {
private:
    std::chrono::high_resolution_clock::time_point startTime;
    
public:
    PerformanceCalculator() {
        startTime = std::chrono::high_resolution_clock::now();
    }
    
    double getElapsedMs() const {
        auto endTime = std::chrono::high_resolution_clock::now();
        auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(endTime - startTime);
        return duration.count();
    }
    
    // Fast vector sum
    static double vectorSum(const std::vector<double>& values) {
        double sum = 0.0;
        for (double v : values) {
            sum += v;
        }
        return sum;
    }
    
    // Fast vector average
    static double vectorAverage(const std::vector<double>& values) {
        if (values.empty()) return 0.0;
        return vectorSum(values) / values.size();
    }
    
    // Fast matrix multiplication simulation
    static double matrixOperation(int size) {
        std::vector<std::vector<double>> matrix(size, std::vector<double>(size, 1.5));
        double result = 0.0;
        
        for (int i = 0; i < size; ++i) {
            for (int j = 0; j < size; ++j) {
                result += matrix[i][j] * matrix[j][i];
            }
        }
        return result;
    }
    
    // Prime number calculation (demonstrates algorithm complexity)
    static int countPrimes(int limit) {
        if (limit < 2) return 0;
        
        std::vector<bool> isPrime(limit + 1, true);
        isPrime[0] = isPrime[1] = false;
        
        for (int i = 2; i * i <= limit; ++i) {
            if (isPrime[i]) {
                for (int j = i * i; j <= limit; j += i) {
                    isPrime[j] = false;
                }
            }
        }
        
        int count = 0;
        for (bool prime : isPrime) {
            if (prime) count++;
        }
        return count;
    }
};

int main(int argc, char* argv[]) {
    try {
        PerformanceCalculator calc;
        JsonOutput output;
        
        // Determine operation from arguments
        std::string operation = "test";
        int size = 100;
        
        for (int i = 1; i < argc; ++i) {
            std::string arg = argv[i];
            if (arg == "--operation" && i + 1 < argc) {
                operation = argv[++i];
            } else if (arg == "--size" && i + 1 < argc) {
                size = std::stoi(argv[++i]);
            }
        }
        
        output.startObject();
        output.addString("status", "success");
        output.addString("operation", operation);
        
        // Perform operation
        if (operation == "sum") {
            std::vector<double> values = {1.5, 2.5, 3.5, 4.5, 5.5};
            double result = PerformanceCalculator::vectorSum(values);
            output.addNumber("result", result);
            output.addNumber("items_processed", (double)values.size());
            
        } else if (operation == "average") {
            std::vector<double> values = {10.0, 20.0, 30.0, 40.0, 50.0};
            double result = PerformanceCalculator::vectorAverage(values);
            output.addNumber("result", result);
            output.addNumber("items_processed", (double)values.size());
            
        } else if (operation == "matrix") {
            double result = PerformanceCalculator::matrixOperation(size);
            output.addNumber("result", result);
            output.addNumber("matrix_size", (double)size);
            
        } else if (operation == "primes") {
            int primeCount = PerformanceCalculator::countPrimes(size);
            output.addNumber("result", (double)primeCount);
            output.addNumber("limit", (double)size);
            
        } else {
            output.addString("result", "test output - no operation specified");
        }
        
        output.addNumber("performance_ms", calc.getElapsedMs());
        output.endObject();
        
        std::cout << output.toString() << std::endl;
        return 0;
        
    } catch (const std::exception& e) {
        JsonOutput errorOutput;
        errorOutput.startObject();
        errorOutput.addString("status", "error");
        errorOutput.addString("message", e.what());
        errorOutput.endObject();
        
        std::cout << errorOutput.toString() << std::endl;
        return 1;
    }
}
