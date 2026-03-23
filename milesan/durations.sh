echo "For memshade:"
echo "Build"
python3 $(MILESAN_PYTHON_COMMON)/compute_durations.py /data/flsolt/gits/memshade-designs/cellift-openc910-memshade/milesan/generated/timestamps/generated_memshade_precompact_start.txt /data/flsolt/gits/memshade-designs/cellift-openc910-memshade/milesan/generated/timestamps/generated_memshade_precompact_end.txt
echo "Verilator elaboration"
python3 $(MILESAN_PYTHON_COMMON)/compute_durations.py /data/flsolt/gits/memshade-designs/cellift-openc910-memshade/milesan/generated/timestamps/run_memshade_notrace_start.txt /data/flsolt/gits/memshade-designs/cellift-openc910-memshade/milesan/generated/timestamps/run_memshade_notrace_end.txt
