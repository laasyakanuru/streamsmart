#!/bin/bash

echo "📊 StreamSmart Logs"
echo "==================="
echo ""
echo "Choose what to view:"
echo "  1) Backend logs"
echo "  2) Frontend logs"
echo "  3) Both (split screen)"
echo "  4) Live tail (backend)"
echo "  5) Live tail (frontend)"
echo ""
read -p "Enter choice (1-5): " choice

case $choice in
    1)
        echo ""
        echo "📄 Backend Logs (last 50 lines):"
        echo "================================="
        tail -50 logs/backend.log
        ;;
    2)
        echo ""
        echo "📄 Frontend Logs (last 50 lines):"
        echo "=================================="
        tail -50 logs/frontend.log
        ;;
    3)
        echo ""
        echo "📄 Backend Logs:"
        echo "================"
        tail -30 logs/backend.log
        echo ""
        echo "📄 Frontend Logs:"
        echo "================="
        tail -30 logs/frontend.log
        ;;
    4)
        echo ""
        echo "📡 Live Backend Logs (Ctrl+C to exit):"
        echo "======================================"
        tail -f logs/backend.log
        ;;
    5)
        echo ""
        echo "📡 Live Frontend Logs (Ctrl+C to exit):"
        echo "======================================="
        tail -f logs/frontend.log
        ;;
    *)
        echo "Invalid choice"
        ;;
esac

